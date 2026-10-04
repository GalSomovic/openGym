import Foundation
import JavaScriptCore

/// openGym's training engine, running in JavaScriptCore.
///
/// The native app does not reimplement progression, 1RM, supersets,
/// recovery or imports: it runs openGym's own unit-tested modules
/// (`apple/core/entry.js`, bundled by `apple/core/build.sh`) so results match
/// openGym exactly and upstream fixes arrive with a rebuild. Values cross the
/// boundary as JSON, the same shape openGym persists and backs up.
public final class Engine: @unchecked Sendable {
    public static let shared = Engine()

    private let context: JSContext
    private let og: JSValue
    private let lock = NSLock()

    public enum Failure: Error, CustomStringConvertible {
        case missingEngine, exception(String), notJSON
        public var description: String {
            switch self {
            case .missingEngine: "engine.js is missing from the bundle"
            case .exception(let m): "engine exception: \(m)"
            case .notJSON: "engine returned a value that is not JSON"
            }
        }
    }

    private init() {
        context = JSContext()!
        var lastError: String?
        context.exceptionHandler = { _, value in lastError = value?.toString() }
        // The modules never touch the DOM; these are the few globals some
        // helpers expect to exist.
        context.evaluateScript("""
        var globalThis = this; var window = this; var self = this;
        var console = { log(){}, warn(){}, error(){}, info(){}, debug(){} };
        """)
        if let url = Bundle.module.url(forResource: "engine", withExtension: "js"),
           let source = try? String(contentsOf: url, encoding: .utf8) {
            context.evaluateScript(source, withSourceURL: url)
        }
        og = context.objectForKeyedSubscript("OG")
        if let lastError { assertionFailure("engine failed to load: \(lastError)") }
    }

    public var isLoaded: Bool { !og.isUndefined }

    /// Calls `OG.<module>.<function>(...args)` with JSON-encodable arguments and
    /// decodes the result.
    public func call<T: Decodable>(_ module: String, _ function: String, _ args: [Any] = [],
                                   as type: T.Type = T.self) throws -> T {
        lock.lock(); defer { lock.unlock() }
        guard isLoaded else { throw Failure.missingEngine }
        var thrown: String?
        context.exceptionHandler = { _, value in thrown = value?.toString() }
        let fn = og.objectForKeyedSubscript(module).objectForKeyedSubscript(function)!
        let jsArgs: [Any] = try args.map { arg in
            if arg is NSNull { return NSNull() }
            let data = try JSONSerialization.data(withJSONObject: arg, options: [.fragmentsAllowed])
            return context.evaluateScript("(\(String(decoding: data, as: UTF8.self)))") as Any
        }
        let result = fn.call(withArguments: jsArgs)
        if let thrown { throw Failure.exception(thrown) }
        let json = context.objectForKeyedSubscript("JSON").invokeMethod("stringify", withArguments: [result as Any])
        guard let text = json?.toString(), text != "undefined", let data = text.data(using: .utf8) else {
            throw Failure.notJSON
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Reads `OG.<module>.<constant>`.
    public func value<T: Decodable>(_ module: String, _ name: String, as type: T.Type = T.self) throws -> T {
        lock.lock(); defer { lock.unlock() }
        let v = og.objectForKeyedSubscript(module).objectForKeyedSubscript(name)
        let json = context.objectForKeyedSubscript("JSON").invokeMethod("stringify", withArguments: [v as Any])
        guard let text = json?.toString(), let data = text.data(using: .utf8) else { throw Failure.notJSON }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
