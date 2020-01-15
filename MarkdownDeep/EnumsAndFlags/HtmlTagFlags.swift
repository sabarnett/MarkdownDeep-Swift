// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
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
