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

struct FootnoteHelper {
    private var m: Markdown
    private var p: BlockProcessor!

    init(m: Markdown) {
        self.m = m
        self.p = nil
    }

    init(m: Markdown, p: BlockProcessor) {
        self.m = m
        self.p = p
    }

    /// Using a list of references, build a footnote
    /// - Parameter lines: The lines read from the file.
    func build(_ lines: inout [Block]) -> Block {
        //  Collapse all plain lines (ie: handle hardwrapped lines)
        var i = 0
        while i < lines.count {
            i += 1
            if i == lines.count {
                break
            }
            //  Join plain paragraphs
            if (lines[i].blockType == BlockType.p) && ((lines[i - 1].blockType == BlockType.p) || (lines[i - 1].blockType == BlockType.footnote)) {

                lines[i - 1].contentEnd = lines[i].contentEnd

                lines.remove(at: i)
                i -= 1
                continue
            }
        }
        //  Build a new string containing all child items
        var sb = ""
        for l in lines {
            sb.append(l.buf!.substring(from: l.contentStart, for: l.contentLen))
            sb.append("\n")
        }

        //  Create the item and process child blocks
        let item = Block()
        item.blockType = BlockType.footnote
        item.data = lines[0].data
        item.children = BlockProcessor(m, p.m_bMarkdownInHtml, BlockType.footnote).process(sb)
        lines.removeAll()

        //  Continue processing after this item
        return item
    }

    /// Render the footnote sin the output HTML
    /// - Parameters:
    ///   - footnotes: The list of footnotes we built
    ///   - sb: The output buffer to add the html to.
    func render(footnotes: [Block], buffer sb: inout String) {
        sb.append("\n<div class=\"\(m.htmlClassFootnotes!)\">\n")
        sb.append("<hr />\n")
        sb.append("<ol>\n")

        for fn in footnotes {
            let fnData = (fn.data as? String) ?? ""
            sb.append("<li id=\"fn:")
            sb.append(fnData)
            //  footnote id
            sb.append("\">\n")
            //  We need to get the return link appended to the last paragraph
            //  in the footnote
            let strReturnLink: String = "<a href=\"#fnref:" + fnData + "\" rev=\"footnote\">&#8617;</a>"

            //  Get the last child of the footnote
            var child = fn.children[fn.children.count - 1]
            if child.blockType == BlockType.p {
                child.blockType = BlockType.p_footnote
                child.data = strReturnLink
            } else {
                child = Block()
                child.contentLen = 0
                child.blockType = BlockType.p_footnote
                child.data = strReturnLink
                fn.children.append(child)
            }
            fn.render(m, &sb)
            sb.append("</li>\n")
        }

        sb.append("</ol>\n")
        sb.append("</div>\n")

    }
}
