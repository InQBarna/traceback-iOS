//
//  TracebackLogger.swift
//  traceback-ios
//
//  Created by Sergi Hernanz on 7/4/25.
//

struct Logger {
    var info: (_ message: @autoclosure @escaping () -> String) -> Void
    var debug: (_ message: @autoclosure @escaping () -> String) -> Void
    var error: (_ message: @autoclosure @escaping () -> String) -> Void
}

