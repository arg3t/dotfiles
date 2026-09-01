import Foundation

// Sony "Headphones Connect" framing (community reverse-engineered, see
// github.com/Plutoberth/SonyHeadphonesClient).
//
// Frame layout (between markers, after escape-decoding):
//   [dataType:1][seq:1][len:4 BE][payload:len][checksum:1]
// Checksum = sum of (dataType, seq, len bytes, payload) modulo 256.
// Inside the framed body, any 0x3C / 0x3D / 0x3E byte is escaped as
// 0x3D followed by (byte & 0xEF); on decode the byte after 0x3D is
// restored by OR-ing with 0x10.

enum SonyDataType: UInt8 {
    case ack = 0x01
    case command1 = 0x0C
    case command1Response = 0x0D
}

struct SonyPacket {
    let dataType: SonyDataType
    let sequence: UInt8
    let payload: [UInt8]
}

enum SonyFraming {
    static let startMarker: UInt8 = 0x3E
    static let endMarker: UInt8 = 0x3C
    static let escapeByte: UInt8 = 0x3D
    static let escapeMask: UInt8 = 0xEF

    static func encode(_ packet: SonyPacket) -> Data {
        var body: [UInt8] = []
        body.append(packet.dataType.rawValue)
        body.append(packet.sequence)
        let len = UInt32(packet.payload.count)
        body.append(UInt8((len >> 24) & 0xFF))
        body.append(UInt8((len >> 16) & 0xFF))
        body.append(UInt8((len >> 8) & 0xFF))
        body.append(UInt8(len & 0xFF))
        body.append(contentsOf: packet.payload)
        let checksum = body.reduce(UInt8(0)) { $0 &+ $1 }
        body.append(checksum)

        var framed: [UInt8] = [startMarker]
        for byte in body {
            if byte == startMarker || byte == endMarker || byte == escapeByte {
                framed.append(escapeByte)
                framed.append(byte & escapeMask)
            } else {
                framed.append(byte)
            }
        }
        framed.append(endMarker)
        return Data(framed)
    }
}

final class SonyFrameParser {
    private enum State {
        case waitingForStart
        case readingBody
    }

    private var state: State = .waitingForStart
    private var buffer: [UInt8] = []
    private var escapeNext: Bool = false

    func reset() {
        state = .waitingForStart
        buffer.removeAll(keepingCapacity: true)
        escapeNext = false
    }

    func feed(_ data: Data) -> [SonyPacket] {
        var packets: [SonyPacket] = []
        for byte in data {
            switch state {
            case .waitingForStart:
                if byte == SonyFraming.startMarker {
                    state = .readingBody
                    buffer.removeAll(keepingCapacity: true)
                    escapeNext = false
                }
            case .readingBody:
                if byte == SonyFraming.endMarker {
                    if let packet = decodeBody(buffer) {
                        packets.append(packet)
                    }
                    state = .waitingForStart
                } else if escapeNext {
                    buffer.append(byte | ~SonyFraming.escapeMask)
                    escapeNext = false
                } else if byte == SonyFraming.escapeByte {
                    escapeNext = true
                } else if byte == SonyFraming.startMarker {
                    // Resync on stray start marker
                    buffer.removeAll(keepingCapacity: true)
                    escapeNext = false
                } else {
                    buffer.append(byte)
                }
            }
        }
        return packets
    }

    private func decodeBody(_ body: [UInt8]) -> SonyPacket? {
        guard body.count >= 7 else { return nil }
        let dataTypeByte = body[0]
        let seq = body[1]
        let len = (UInt32(body[2]) << 24) | (UInt32(body[3]) << 16) | (UInt32(body[4]) << 8) | UInt32(body[5])
        guard body.count == 7 + Int(len) else { return nil }
        let payload = Array(body[6..<(6 + Int(len))])
        let checksum = body[6 + Int(len)]
        let computed = body.prefix(6 + Int(len)).reduce(UInt8(0)) { $0 &+ $1 }
        guard computed == checksum else { return nil }
        guard let dataType = SonyDataType(rawValue: dataTypeByte) else {
            return SonyPacket(dataType: .command1, sequence: seq, payload: payload)
        }
        return SonyPacket(dataType: dataType, sequence: seq, payload: payload)
    }
}
