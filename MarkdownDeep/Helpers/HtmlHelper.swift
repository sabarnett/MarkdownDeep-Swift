// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import Foundation

struct HtmlHelper {

    // MARK:- Allowed tags

    static let allowedTypes: [String] = [        "b","blockquote","code","dd","dt","dl","del","em",
        "h1","h2","h3","h4","h5","h6","i","kbd","li","ol","ul",
        "p", "pre", "s", "sub", "sup", "strong", "strike", "img", "a"
    ]

    static func isAllowedType(tag: String) -> Bool {
        return allowedTypes.firstIndex(of: tag.lowercased()) != nil
    }

    // MARK:- Allowed attributes for the specified HTML tag

    static let allowedAttributes: [String: [String]] =
    [
        "a": [ "href", "title", "class" ],
        "img": [ "src", "width", "height", "alt", "title", "class" ]
    ]

    static func attributesForTag(tag: String) -> [String] {
        return allowedAttributes[tag.lowercased()] ?? []
    }
    
    // MARK:- Formatting flags for an HTML tag

    static let tagNameFlags: [String: HtmlTagFlags] =
    [
        "p": [HtmlTagFlags.Block,  HtmlTagFlags.ContentAsSpan],
        "div": [HtmlTagFlags.Block],
        "h1": [HtmlTagFlags.Block,  HtmlTagFlags.ContentAsSpan],
        "h2": [HtmlTagFlags.Block, HtmlTagFlags.ContentAsSpan],
        "h3": [HtmlTagFlags.Block, HtmlTagFlags.ContentAsSpan],
        "h4": [HtmlTagFlags.Block, HtmlTagFlags.ContentAsSpan],
        "h5": [HtmlTagFlags.Block, HtmlTagFlags.ContentAsSpan],
        "h6": [HtmlTagFlags.Block, HtmlTagFlags.ContentAsSpan],
        "blockquote": HtmlTagFlags.Block,
        "pre": HtmlTagFlags.Block,
        "table": HtmlTagFlags.Block,
        "dl": HtmlTagFlags.Block,
        "ol": HtmlTagFlags.Block,
        "ul": HtmlTagFlags.Block,
        "form": HtmlTagFlags.Block,
        "fieldset": HtmlTagFlags.Block,
        "iframe": HtmlTagFlags.Block,
        "script": [HtmlTagFlags.Block, HtmlTagFlags.Inline],
        "noscript": [HtmlTagFlags.Block, HtmlTagFlags.Inline],
        "math": [HtmlTagFlags.Block, HtmlTagFlags.Inline],
        "ins": [HtmlTagFlags.Block, HtmlTagFlags.Inline],
        "del": [HtmlTagFlags.Block, HtmlTagFlags.Inline],
        "img": [HtmlTagFlags.Block, HtmlTagFlags.Inline],
        "li": HtmlTagFlags.ContentAsSpan,
        "dd": HtmlTagFlags.ContentAsSpan,
        "dt": HtmlTagFlags.ContentAsSpan,
        "td": HtmlTagFlags.ContentAsSpan,
        "th": HtmlTagFlags.ContentAsSpan,
        "legend": HtmlTagFlags.ContentAsSpan,
        "address": HtmlTagFlags.ContentAsSpan,
        "hr": [HtmlTagFlags.Block, HtmlTagFlags.NoClosing],
        "!": [HtmlTagFlags.Block, HtmlTagFlags.NoClosing],
        "head": HtmlTagFlags.Block
    ]

    static func flagsForTag(tag: String) -> HtmlTagFlags? {
        return HtmlHelper.tagNameFlags[tag.lowercased()]
    }

    
}
