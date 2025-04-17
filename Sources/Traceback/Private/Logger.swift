//
//  TracebackLogger.swift
//  traceback-ios
//
//  Created by Sergi Hernanz on 7/4/25.
//

import os

struct Logger {
    private let logger: os.Logger
    private let level: TracebackConfiguration.LogLevel

    init(subsystem: String = "com.inqbarna.traceback", level: TracebackConfiguration.LogLevel) {
        self.logger = os.Logger(subsystem: subsystem, category: "traceback")
        self.level = level
    }

    func info(_ message: @autoclosure @escaping () -> String) {
        guard level == .info || level == .debug else { return }
        logger.info("\(message())")
    }

    func debug(_ message: @autoclosure @escaping () -> String) {
        guard level == .debug else { return }
        logger.debug("\(message())")
    }

    func error(_ message: @autoclosure @escaping () -> String) {
        logger.error("\(message())")
    }
}
