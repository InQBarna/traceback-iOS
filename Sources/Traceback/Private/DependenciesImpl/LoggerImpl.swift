//
//  LoggerImpl.swift
//  Traceback
//
//  Created by Sergi Hernanz on 27/9/25.
//

import os

extension Logger {
    // init {
    static func live(
        level: TracebackConfiguration.LogLevel = .info
    ) -> Logger {
        let subsystem: String = "com.inqbarna.traceback"
        let logger: os.Logger = os.Logger(subsystem: subsystem, category: "traceback")
        let level: TracebackConfiguration.LogLevel = level
        return Logger(
            info: { message in
                guard level == .info || level == .debug else { return }
                logger.info("[Traceback] \(message())")
            },
            debug: { message in
                guard level == .debug else { return }
                logger.debug("[Traceback] \(message())")
            },
            error: { message in
                logger.error("[Traceback] \(message())")
            }
        )
    }
}
