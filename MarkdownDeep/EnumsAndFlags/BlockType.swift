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

// NOTE: Some block types are only used during block parsing, some
// are only used during rendering and some are used during both

enum BlockType: Int, CustomStringConvertible
{
    case Blank            // blank line (parse only)
    case h1                // headings (render and parse)
    case h2
    case h3
    case h4
    case h5
    case h6
    case post_h1    // setext heading lines (parse only)
    case post_h2
    case quote      // block quote (render and parse)
    case ol_li      // list item in an ordered list    (render and parse)
    case ul_li      // list item in an unordered list (render and parse)
    case p          // paragraph (or plain line during parse)
    case indent     // an indented line (parse only)
    case hr         // horizontal rule (render and parse)
    case user_break // user break
    case html       // html content (render and parse)
    case unsafe_html // unsafe html that should be encoded
    case span       // an undecorated span of text (used for simple list items
                    // where content is not wrapped in paragraph tags
    case codeblock  // a code block (render only)
    case li         // a list item (render only)
    case ol         // ordered list (render only)
    case ul         // unordered list (render only)
    case HtmlTag    // Data=(HtmlTag), children = content
    case Composite  // Just a list of child blocks
    case table_spec // A table row specifier eg:  |---: | ---|    `data` = TableSpec reference
    case dd         // definition (render and parse)
                    // `data` = bool true if blank line before
    case dt         // render only
    case dl         // render only
    case footnote   // footnote definition  eg: [^id]
                    // `data` holds the footnote id
    case p_footnote // paragraph with footnote return link append.
                    // Return link string is in `data`.

    var description: String {
        switch self {
        case .h1: return "h1"
        case .h2: return "h2"
        case .h3: return "h3"
        case .h4: return "h4"
        case .h5: return "h5"
        case .h6: return "h6"
        case .post_h1: return "h1"
        case .post_h2: return "h2"
        case .quote: return "quote"
        case .ol_li: return "li"
        case .ul_li: return "li"
        case .p: return "p"
        case .indent: return "\t"
        case .hr: return "hr"
        case .user_break: return "&nbsp"
        case .html: return "html"
        case .unsafe_html: return "html"
        case .span: return "span"
        case .codeblock: return "code"
        case .li: return "li"
        case .ol: return "ol"
        case .ul: return "ul"
        case .HtmlTag: return "??"
        case .Composite: return "??"
        case .table_spec: return "??"
        case .dd: return "dd"
        case .dt: return "dt"
        case .dl: return "dl"
        case .footnote: return "footnote"
        case .p_footnote: return "??"

        default: return "??"
        }
    }
}
