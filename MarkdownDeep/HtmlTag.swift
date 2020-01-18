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

class HtmlTag
{
    var tagName: String = ""
    var tagAttributes = CSDictionary<String>()
    var tagClosed: Bool = false
    var tagClosing: Bool = false
    var tagFlags: HtmlTagFlags = HtmlTagFlags.NotSet

    init(name: String) { tagName = name; }

    // MARK:- Attribute support

    var attributes: CSDictionary<String> {
        get { return tagAttributes; }
    }

    func attribute(key: String) -> String! {
        return tagAttributes[key]
    }

    func addAttribute(key: String, value: String) {
        tagAttributes[key] = value
    }

    func removeAttribute(key: String) {
        tagAttributes.remove(itemWithKey: key)
    }

    // MARK:- Computed Properties

    // Get the tag name eg: "div"
    var name: String {
        get { return tagName; }
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
                if let flagsForTag = HtmlHelper.flagsForTag(tag: name.lowercased()) {
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

    // MARK:- Public interface

    // Check if this tag is safe
    func isSafe() -> Bool
    {
        return HtmlHelper.isTagSafe(tag: name, withAttributes: tagAttributes)
    }

    // Render opening tag (eg: <tag attr="value">
    func renderOpening(_ dest: inout String)
    {
        dest.append("<");
        dest.append(name);

        for (key, attr) in attributes {
            dest.append(" \(key)=\"\(attr)\"")
        }

        if (tagClosed) {
            dest.append(" />")
        } else {
            dest.append(">")
        }
    }

    // Render closing tag (eg: </tag>)
    func renderClosing(_ dest: inout String)
    {
        dest.append("</\(name)>")
    }

    static func parse(str: String, pos: inout Int) -> HtmlTag?
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

    static func parse(scanner p: StringScanner) -> HtmlTag?
    {
        // Save position
        let savepos: Int = p.position;

        // Parse it
        let ret = HtmlHelper.parseTag(p);
        if (ret != nil) {
            return ret;
        }

        // Rewind if failed
        p.position = savepos;
        return nil;
    }

}
