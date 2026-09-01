import Foundation

// Sends a system-wide Pause command via Apple's MediaRemote framework.
//
// MediaRemote is a private framework but has been ABI-stable for years
// and is what tools like NepTunes and various Now-Playing menu apps use.
// We dlopen it at runtime so we don't need a link-time dependency or a
// .tbd stub. `kMRPause = 1` pauses idempotently — if nothing is playing,
// the call is a no-op (unlike simulating the Play/Pause media key, which
// would start playback when paused).
final class MediaController {
    private typealias SendCommandFn = @convention(c) (Int, AnyObject?) -> Bool
    private var sendCommand: SendCommandFn?

    init() {
        let url = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, url as CFURL) else {
            FileLogger.shared.log("media", "MediaRemote.framework not loadable")
            return
        }
        let symbol = "MRMediaRemoteSendCommand" as CFString
        guard let ptr = CFBundleGetFunctionPointerForName(bundle, symbol) else {
            FileLogger.shared.log("media", "MRMediaRemoteSendCommand symbol missing")
            return
        }
        sendCommand = unsafeBitCast(ptr, to: SendCommandFn.self)
    }

    func pause() {
        guard let fn = sendCommand else {
            FileLogger.shared.log("media", "pause skipped — MediaRemote unavailable")
            return
        }
        let kMRPause = 1
        let ok = fn(kMRPause, nil)
        FileLogger.shared.log("media", "pause sent (ok=\(ok))")
    }
}
