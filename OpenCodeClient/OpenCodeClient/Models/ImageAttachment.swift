//
//  ImageAttachment.swift
//  OpenCodeClient
//

import Foundation

struct ImageAttachment: Identifiable, Equatable, Sendable {
    let id: UUID
    let data: Data
    let mime: String
    let filename: String

    init(id: UUID = UUID(), data: Data, mime: String, filename: String) {
        self.id = id
        self.data = data
        self.mime = mime
        self.filename = filename
    }

    nonisolated var dataURL: String {
        "data:\(mime);base64,\(data.base64EncodedString())"
    }
}
