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

    static func isTagSafe(tag tagName: String, withAttributes tagAttributes: CSDictionary<String>) -> Bool {

        // Check if tag is in whitelist
        if !HtmlHelper.isAllowedType(tag: tagName) {
            return false
        }

        // Find allowed attributes
        let allowed_attributes: [String] = HtmlHelper.attributesForTag(tag: tagName)
        if (allowed_attributes.count == 0)
        {
            // No allowed attributes, check we don't have any
            return tagAttributes.count == 0
        }

        // Check all are allowed
        for (key, _) in tagAttributes {
            let keyLower = key.lowercased()
            if !allowed_attributes.contains(keyLower) {
                // attribute is not allowed
                return false
            }
        }

        // Check href attribute is ok
        if let href = tagAttributes["href"] {
            if (!Utils.isSafeUrl(href)) {
                return false;
            }
        }

        if let src = tagAttributes["src"] {
            if (!Utils.isSafeUrl(src)) {
                return false;
            }
        }

        // Passed all white list checks, allow it
        return true;
    }

    static func parseTag(_ p: StringScanner) -> HtmlTag?
    {
        // Does it look like a tag?
        if (p.current != "<") {
            return nil;
        }

        // Skip '<'
        p.skipForward(1);

        // Is it a comment?
        if (p.skipString("!--"))
        {
            p.markPosition()

            if (p.find("-->"))
            {
                let t: HtmlTag = HtmlTag(name: "!")
                t.addAttribute(key: "content", value: p.extract())
                t.tagClosed = true
                p.skipForward(3)
                return t
            }
        }

        // Is it a closing tag eg: </div>
        let bClosing: Bool = p.skipChar("/")

        // Get the tag name
        var tagName: String? = "";
        if (!p.skipIdentifier(&tagName)) {
            return nil
        }

        // Probably a tag, create the HtmlTag object now
        let tag = HtmlTag(name: tagName!)
        tag.tagClosing = bClosing

        // If it's a closing tag, no attributes
        if (bClosing)
        {
            if (p.current != ">") {
                return nil
            }

            p.skipForward(1)
            return tag
        }

        while (!p.eof)
        {
            // Skip whitespace
            p.skipWhitespace();

            // Check for closed tag eg: <hr />
            if (p.skipString("/>"))
            {
                tag.tagClosed = true
                return tag
            }

            // End of tag?
            if (p.skipChar(">")) {
                return tag
            }

            // attribute name
            var attributeName: String? = ""
            if (!p.skipIdentifier(&attributeName)) {
                return nil
            }

            // Skip whitespace
            p.skipWhitespace();

            // Skip equal sign
            if (p.skipChar("="))
            {
                // Skip whitespace
                p.skipWhitespace();

                // Optional quotes
                if (p.skipChar("\""))
                {
                    // Scan the value
                    p.markPosition();
                    if (!p.find("\"")) {
                        return nil;
                    }

                    // Store the value
                    tag.addAttribute(key: attributeName!, value: p.extract());

                    // Skip closing quote
                    p.skipForward(1);
                }
                else
                {
                    // Scan the value
                    p.markPosition();
                    while !p.eof
                        && !p.current.isWhitespace
                        && (p.current != ">")
                        && (p.current != "/") {
                        p.skipForward(1)
                    }

                    if (!p.eof)
                    {
                        // Store the value
                        tag.addAttribute(key: attributeName!, value: p.extract())
                    }
                }
            }
            else
            {
                tag.addAttribute(key: attributeName!, value: "")
            }
        }

        return nil;
    }

    /// HtmlEncode a range in a string to a specified string builder
    /// - Parameters:
    ///   - dest: The buffer to add the results to
    ///   - str: The string to be encoded
    ///   - start: The start position within the string
    ///   - len: The length of text to encode
    static func htmlEncode(_ dest: inout String, _ str: String, _ start: Int, _ len: Int) {
        let p = StringScanner(str, start, len)
        while !p.eof {
            let ch = p.current
            switch ch {
                case "&":
                    dest.append("&amp;")
                case "<":
                    dest.append("&lt;")
                case ">":
                    dest.append("&gt;")
                case "\"":
                    dest.append("&quot;")
                default:
                    dest.append(ch)
            }
            p.skipForward(1)
        }
    }

    /// HtmlEncode a string, also converting tabs to spaces (used by CodeBlocks)
    /// - Parameters:
    ///   - dest: The buffer to add the output to
    ///   - str: The string to be encoded
    ///   - start: The start position within the string
    ///   - len: The length to be encoded
    static func htmlEncodeAndConvertTabsToSpaces(_ dest: inout String, _ str: String, _ start: Int, _ len: Int) {

        let p = StringScanner(str, start, len)
        var pos: Int = 0
        while !p.eof {
            let ch = p.current
            switch ch {
                case "\t":
                    dest.append(" ")
                    pos += 1
                    while (pos % 4) != 0 {
                        dest.append(" ")
                        pos += 1
                    }
                    pos -= 1
                case "\r", "\n":
                    dest.append("\n")
                    pos = 0
                    p.skipEol()
                    continue
                case "&":
                    dest.append("&amp;")
                case "<":
                    dest.append("&lt;")
                case ">":
                    dest.append("&gt;")
                case "\"":
                    dest.append("&quot;")
                default:
                    dest.append(ch)
            }
            p.skipForward(1)
            pos += 1
        }}

}
