import OSLog
import Foundation
import os
@_exported import os.log

public extension OSLog {
    
    static let pointsOfInterest = OSLog(subsystem: "SummarizedCollection", category: "PointsOfInterest").enabled(true)

    convenience init(_ bundle: Bundle = .main, category: String? = nil) {
        self.init(subsystem: bundle.bundleIdentifier ?? "default", category: category ?? "default")
    }
    
    convenience init(_ aClass: AnyClass, category: String? = nil) {
        self.init(Bundle(for: aClass), category: category ?? String(describing: aClass))
    }
    
    @inlinable func log(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .default, args)
    }
    
    @inlinable func info(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .info, args)
    }
    
    @inlinable func debug(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .debug, args)
    }
    
    @inlinable func error(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .error, args)
    }
    
    @inlinable func fault(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .fault, args)
    }
    
    func enabled(_ enabled: Bool) -> OSLog {
        if enabled {
            return self
        } else {
            return OSLog.disabled
        }
    }
    
    func print(_ value: @autoclosure () -> Any) {
        guard isEnabled(type: .debug) else { return }
        os_log("%{public}@", log: self, type: .debug, String(describing: value()))
    }
    
    func dump(_ value: @autoclosure () -> Any) {
        guard isEnabled(type: .debug) else { return }
        var string = String()
        Swift.dump(value(), to: &string)
        os_log("%{public}@", log: self, type: .debug, string)
    }
    
    func trace(file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        guard isEnabled(type: .debug) else { return }
        let file = URL(fileURLWithPath: String(describing: file)).deletingPathExtension().lastPathComponent
        var function = String(describing: function)
        function.removeSubrange(function.firstIndex(of: "(")!...function.lastIndex(of: ")")!)
        os_log("%{public}@.%{public}@():%ld", log: self, type: .debug, file, function, line)
    }
    
    @usableFromInline internal func log(_ message: StaticString, type: OSLogType, _ a: [CVarArg]) {
        // The Swift overlay of os_log prevents from accepting an unbounded number of args
        // http://www.openradar.me/33203955
        assert(a.count <= 5)
        switch a.count {
        case 5: os_log(message, log: self, type: type, a[0], a[1], a[2], a[3], a[4])
        case 4: os_log(message, log: self, type: type, a[0], a[1], a[2], a[3])
        case 3: os_log(message, log: self, type: type, a[0], a[1], a[2])
        case 2: os_log(message, log: self, type: type, a[0], a[1])
        case 1: os_log(message, log: self, type: type, a[0])
        default: os_log(message, log: self, type: type)
        }
    }
    
    @inlinable func signpostID() -> OSSignpostID {
        return OSSignpostID(log: self)
    }
    
    @inlinable func signpostID(object: AnyObject) -> OSSignpostID {
        return OSSignpostID(log: self, object: object)
    }

    @inlinable func begin(name: StaticString, id: OSSignpostID = .exclusive) {
        os_signpost(.begin, log: self, name: name, signpostID: id)
    }

    @inlinable func begin(name: StaticString, id: OSSignpostID = .exclusive, _ message: StaticString, _ args: CVarArg...) {
        os_signpost(.begin, log: self, name: name, signpostID: id, message, args)
    }

    @inlinable func end(name: StaticString, id: OSSignpostID = .exclusive) {
        os_signpost(.end, log: self, name: name, signpostID: id)
    }

    @inlinable func end(name: StaticString, id: OSSignpostID = .exclusive, _ message: StaticString, _ args: CVarArg...) {
        os_signpost(.end, log: self, name: name, signpostID: id, message, args)
    }

    @inlinable func event(name: StaticString, id: OSSignpostID = .exclusive) {
        os_signpost(.event, log: self, name: name, signpostID: id)
    }

    @inlinable func event(name: StaticString, id: OSSignpostID = .exclusive, _ message: StaticString, _ args: CVarArg...) {
        os_signpost(.event, log: self, name: name, signpostID: id, message, args)
    }
    
}
