import Foundation

final class FileLogger {
    static let shared = FileLogger()

    let url: URL
    private let queue = DispatchQueue(label: "com.tanat.sonyconnect.log")
    private let formatter: DateFormatter

    private init() {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        url = dir.appendingPathComponent("SonyConnect.log")
        formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        log("session", "=== started ===")
    }

    func log(_ tag: String, _ message: String) {
        write("[\(tag)] \(message)")
    }

    func hex(_ tag: String, _ data: Data) {
        let parts = data.map { String(format: "%02X", $0) }
        let hex = parts.joined(separator: " ")
        write("[\(tag)] (\(data.count) bytes) \(hex)")
    }

    private func write(_ line: String) {
        let stamp = formatter.string(from: Date())
        let full = "\(stamp) \(line)\n"
        let target = url
        queue.async {
            guard let data = full.data(using: .utf8) else { return }
            if FileManager.default.fileExists(atPath: target.path) {
                if let handle = try? FileHandle(forWritingTo: target) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                }
            } else {
                try? data.write(to: target)
            }
        }
    }
}
