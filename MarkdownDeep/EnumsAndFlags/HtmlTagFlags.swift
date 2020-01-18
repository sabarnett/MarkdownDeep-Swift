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
