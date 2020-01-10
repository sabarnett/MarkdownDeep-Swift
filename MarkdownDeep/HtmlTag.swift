//
//  MarkdownDeep for SWIFT
//     Copyright (C) 2019 Steven Barnett
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

struct HtmlTagFlags: OptionSet
{
    let rawValue: Int

    static let NotSet = HtmlTagFlags(rawValue: 0x0000)
    static let Block  = HtmlTagFlags(rawValue: 0x0001)    // Block tag
    static let Inline = HtmlTagFlags(rawValue: 0x0002)    // Inline tag
    static let NoClosing = HtmlTagFlags(rawValue: 0x0004)
                // No closing tag (eg: <hr> and <!-- -->)
    static let ContentAsSpan = HtmlTagFlags(rawValue: 0x0008)
                // When markdown=1 treat content as span, not block
}

internal class Attribute {

    init(key: String, value: String) {
        self.key = key
        self.value = value
    }

    var key: String = ""
    var value: String = ""
}

public class HtmlTag
{
    private var tagName: String = ""
    private var tagAttributes = [Attribute]()
    private var tagClosed: Bool = false
    private var tagClosing: Bool = false
    private var tagFlags: HtmlTagFlags = HtmlTagFlags.NotSet

    init(name: String) {
        tagName = name;
    }

    // Get the tag name eg: "div"
    var name: String {
        get { return tagName; }
    }

    // Get a dictionary of attribute values (no decoding done)
    var attributes: [Attribute] {
        get { return tagAttributes; }
    }

    public func attribute(key: String) -> String! {
        if let existingAttribute = tagAttributes.first(where: { (attr) -> Bool in
            attr.key == key
        }) {
            // Found an existing one, return the value
            return existingAttribute.value
        }

        return nil
    }

    public func addAttribute(key: String, value: String) {

        if let existingAttribute = tagAttributes.first(where: { (attr) -> Bool in
            attr.key == key
        }) {
            // Found an existing one, replace it
            existingAttribute.value = value
            return
        }

        let newAttr = Attribute(key: key, value: value)
        tagAttributes.append(newAttr)
    }

    public func removeAttribute(key: String) {

        if let existingIndex = tagAttributes.firstIndex(where: { (attr) -> Bool in
            attr.key == key
        }) {
            tagAttributes.remove(at: existingIndex)
        }

    }

    // Is this tag closed eg; <br />
    var closed: Bool
    {
        get { return tagClosed; }
        set { tagClosed = newValue; }
    }

    // Is this a closing tag eg: </div>
    var closing: Bool
    {
        get { return tagClosing; }
    }


    var Flags: HtmlTagFlags
    {
        get
        {
            if (tagFlags == .NotSet)
            {
                if let flagsForTag = tagNameFlags[name.lowercased()] {
                    tagFlags = flagsForTag
                } else {
                    if !tagFlags.contains(HtmlTagFlags.Inline) {
                        tagFlags.insert(HtmlTagFlags.Inline)
                    }
                }
            }

            return tagFlags;
        }
    }

    var allowedTypes: [String] = [        "b","blockquote","code","dd","dt","dl","del","em","h1","h2","h3","h4","h5","h6","i","kbd","li","ol","ul",
        "p", "pre", "s", "sub", "sup", "strong", "strike", "img", "a"
    ]

    var allowedAttributes: [String: [String]] =
    [
        "a": [ "href", "title", "class" ],
        "img": [ "src", "width", "height", "alt", "title", "class" ]
    ]

    var tagNameFlags: [String: HtmlTagFlags] =
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

    // Check if this tag is safe
    public func isSafe() -> Bool
    {
        let nameLower : String = tagName.lowercased()

        // Check if tag is in whitelist
        if (allowedTypes.firstIndex(of: nameLower) == nil) {
            return false
        }

        // Find allowed attributes
        let allowed_attributes: [String] = allowedAttributes[nameLower] ?? [];
        if (allowed_attributes.count == 0)
        {
            // No allowed attributes, check we don't have any
            return tagAttributes.count == 0
        }

        // Check all are allowed
        for (attr) in tagAttributes {
            let keyLower = attr.key.lowercased()
            if !allowed_attributes.contains(keyLower) {
                // attribute is not allowed
                return false
            }
        }

        // Check href attribute is ok
        if let href = attribute(key: "href") {
            if (!Utils.isSafeUrl(href)) {
                return false;
            }
        }

        if let src = attribute(key: "src") {
            if (!Utils.isSafeUrl(src)) {
                return false;
            }
        }

        // Passed all white list checks, allow it
        return true;
    }

    // Render opening tag (eg: <tag attr="value">
    public func renderOpening(_ dest: inout String)
    {
        dest.append("<");
        dest.append(name);

        for attr in attributes {
            dest.append(" ")
            dest.append(attr.key)
            dest.append("=\"")
            dest.append(attr.value)
            dest.append("\"")
        }

        if (tagClosed) {
            dest.append(" />")
        } else {
            dest.append(">")
        }
    }

    // Render closing tag (eg: </tag>)
    public func renderClosing(_ dest: inout String)
    {
        dest.append("</\(name)>")
    }


    public static func parse(str: String, pos: inout Int) -> HtmlTag?
    {
        let sp: StringScanner = StringScanner(str, pos)
        let ret = parse(scanner: sp)

        if (ret != nil)
        {
            pos = sp.position
            return ret
        }

        return nil;
    }

    public static func parse(scanner p: StringScanner) -> HtmlTag?
    {
        // Save position
        let savepos: Int = p.position;

        // Parse it
        let ret = parseHelper(p);
        if (ret != nil) {
            return ret;
        }

        // Rewind if failed
        p.position = savepos;
        return nil;
    }

    private static func parseHelper(_ p: StringScanner) -> HtmlTag?
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
}
