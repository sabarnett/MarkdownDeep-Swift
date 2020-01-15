// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import Foundation

internal enum TokenType: Int, CustomStringConvertible {

    var description: String {
        switch self {
        case .Text: return "Text"
        case .HtmlTag: return "HtmlTag"
        case .Html: return "Html"
        case .open_em: return "open_em"
        case .close_em: return "close_em"
        case .open_strong: return "open_strong"
        case .close_strong: return "close_strong"
        case .code_span: return "code_span"
        case .br: return "br"
        case .link: return "link"
        case .img: return "img"
        case .footnote: return "footnote"
        case .abbreviation: return "abbreviation"
        case .opening_mark: return "opening_mark"
        case .closing_mark: return "closing_mark"
        case .internal_mark: return "internal_mark"
        }
    }

    case Text
    case HtmlTag
    case Html
    case open_em
    case close_em
    case open_strong
    case close_strong
    case code_span
    case br
    case link
    case img
    case footnote
    case abbreviation
    case opening_mark
    case closing_mark
    case internal_mark
}
