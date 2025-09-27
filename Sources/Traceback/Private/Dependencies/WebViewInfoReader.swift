//
//  Navigator.swift
//  Traceback
//
//  Created by Sergi Hernanz on 27/9/25.
//

struct WebViewInfo {
    let language: String?
    let appVersion: String?
}

struct WebViewInfoReader {
    let getInfo: () async -> WebViewInfo?
}
