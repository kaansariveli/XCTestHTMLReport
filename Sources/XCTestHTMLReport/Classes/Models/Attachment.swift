//
//  Attachment.swift
//  XCTestHTMLReport
//
//  Created by Titouan van Belle on 22.07.17.
//  Copyright © 2017 Tito. All rights reserved.
//

import Foundation
import XCResultKit

enum AttachmentType: String {
    case unknown = ""
    case data = "public.data"
    case html = "public.html"
    case jpeg = "public.jpeg"
    case png = "public.png"
    case text = "public.plain-text"

    var cssClass: String {
        switch self {
        case .png, .jpeg:
            return "screenshot"
        case .text:
            return "text"
        default:
            return ""
        }
    }

    fileprivate var mimeType: String? {
        switch self {
        case .png:
            return "image/png"
        case .jpeg:
            return "image/jpeg"
        case .text:
            return "text/plain"
        case .html:
            return "text/html"
        case .data:
            return "application/octet-stream"
        case .unknown:
            return nil
        }
    }
}

enum AttachmentName: RawRepresentable {
    enum Constant: String {
        case kXCTAttachmentLegacyScreenImageData = "kXCTAttachmentLegacyScreenImageData"
    }
    
    case constant(Constant)
    case custom(String)
    
    var rawValue: String {
        switch self {
        case .constant(let constant):
            return constant.rawValue
        case .custom(let rawValue):
            return rawValue
        }
    }
    
    init(rawValue: String) {
        guard let constant = Constant(rawValue: rawValue) else {
            self = .custom(rawValue)
            return
        }
        
        self = .constant(constant)
    }
}

struct Attachment: HTML
{
    let padding: Int
    let filename: String
    let content: RenderingContent
    let type: AttachmentType
    let name: AttachmentName?

    init(attachment: ActionTestAttachment, file: ResultFile, padding: Int = 0, renderingMode: Summary.RenderingMode) {
        self.filename = attachment.filename ?? ""
        self.type = AttachmentType(rawValue: attachment.uniformTypeIdentifier) ?? .unknown
        self.name = attachment.name.map(AttachmentName.init(rawValue:))
        if let id = attachment.payloadRef?.id {
            self.content = file.exportPayloadContent(
                id: id,
                renderingMode: renderingMode
            )
        } else {
            self.content = .none
        }
        self.padding = padding
    }

    var fallbackDisplayName: String {
        switch type {
        case .png, .jpeg:
            return "Screenshot"
        case .text, .html, .data:
            return "File"
        case .unknown:
            return "Attachment"
        }
    }

    var source: String? {
        switch content {
        case let .data(data):
            guard let mimeType = type.mimeType else {
                return nil
            }
            return "data:\(mimeType);base64,\(data.base64EncodedString())"
        case let .url(url):
            return url.relativePath
        case .none:
            return nil
        }
    }

    var displayName: String {
        switch name {
        case .some(.custom(let customName)):
            return customName
        default:
            return fallbackDisplayName
        }
    }
    
    // PRAGMA MARK: - HTML

    var htmlTemplate: String {
        switch type {
        case .png, .jpeg:
            return HTMLTemplates.screenshot
        case .text, .html, .data:
            return HTMLTemplates.text
        case .unknown:
            return ""
        }
    }

    var htmlPlaceholderValues: [String: String] {
        return [
            "PADDING": String(padding),
            "SOURCE": source ?? "",
            "FILENAME": filename,
            "NAME": displayName
        ]
    }
}

