import Foundation
import os

/// Default logger that routes SDK logs through Apple's unified logging system.
///
/// Uses `OSLog` for broad platform compatibility.
/// The host app can replace this with a custom `IdentityKitLogger` implementation.
public struct DefaultLogger: IdentityKitLogger {
    private let osLog: OSLog

    public init(subsystem: String = "com.identitykit.sdk") {
        self.osLog = OSLog(subsystem: subsystem, category: "IdentityKit")
    }

    public func log(level: LogLevel, message: String, file: String, function: String, line: Int) {
        let fileName = (file as NSString).lastPathComponent
        let formatted = "[\(fileName):\(line)] \(function) — \(message)"

        let osLogType: OSLogType
        switch level {
        case .debug:
            osLogType = .debug
        case .info:
            osLogType = .info
        case .warning:
            osLogType = .default
        case .error:
            osLogType = .error
        case .none:
            return
        }

        os_log("%{public}@", log: osLog, type: osLogType, formatted)
    }
}
