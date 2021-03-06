//
//  MarkdownDeep for SWIFT
//     Copyright (C) 2020 Steven Barnett
//
//  This is a port of the C# version of MarkdownDeep...
//
//   MarkdownDeep - http://www.toptensoftware.com/markdowndeep
//     Copyright (C) 2010-2011 Topten Software
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this product except in compliance with the
//   License. You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing,
//   software distributed under the License is distributed on
//   an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//   either express or implied. See the License for the specific
//   language governing permissions and limitations under the License.
//
import Foundation

enum TokenType: Int {

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

extension TokenType: CustomStringConvertible {

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
}
