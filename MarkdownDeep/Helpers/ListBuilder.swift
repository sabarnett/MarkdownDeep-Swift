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

struct ListBuilder {
    private var m: Markdown
    private var p: BlockProcessor

    init(m: Markdown, p: BlockProcessor) {
        self.m = m
        self.p = p
    }

    /// Builds an ordered <ol> or unordered <ul> list
    /// - Parameter lines: The lines to add to the list
    func build(_ lines: inout [Block]) -> Block {
        //  What sort of list are we dealing with
        let listType: BlockType! = lines[0].blockType

        let leadingSpace: Int = lines[0].leadingSpaces
        var i = 0
        while i < lines.count - 1 {
            i += 1
            //  Join plain paragraphs
            if ((lines[i].blockType == BlockType.p)
                && (lines[i - 1].blockType == BlockType.p
                    || lines[i - 1].blockType == BlockType.ul_li
                    || lines[i - 1].blockType == BlockType.ol_li)) {

                lines[i - 1].contentEnd = lines[i].contentEnd

                lines.remove(at: i)
                i -= 1
                continue
            }
            if lines[i].blockType != BlockType.indent && lines[i].blockType != BlockType.Blank {

                let thisLeadingSpace: Int = lines[i].leadingSpaces
                if thisLeadingSpace > leadingSpace {
                    //  Change line to indented, including original leading chars
                    //  (eg: '* ', '>', '1.' etc...)
                    lines[i].blockType = BlockType.indent
                    let saveend: Int = lines[i].contentEnd
                    lines[i].contentStart = lines[i].lineStart + thisLeadingSpace
                    lines[i].contentEnd = saveend
                }
            }
        }
        //  Create the wrapping list item
        let List = Block(type: (listType == BlockType.ul_li ? BlockType.ul : BlockType.ol))
        List.children = []

        //  Process all lines in the range
        i = -1
        while i < lines.count - 1 {
            i += 1

            //  Find start of item, including leading blanks
            var start_of_li: Int = i
            while (start_of_li > 0) && (lines[start_of_li - 1].blockType == BlockType.Blank) {
                start_of_li -= 1
            }

            //  Find end of the item, including trailing blanks
            var end_of_li: Int = i
            while (end_of_li < (lines.count - 1))
                && (lines[end_of_li + 1].blockType != BlockType.ul_li)
                && (lines[end_of_li + 1].blockType != BlockType.ol_li) {
                end_of_li += 1
            }

            //  Is this a simple or complex list item?
            if start_of_li == end_of_li {
                //  It's a simple, single line item item
            //    System.Diagnostics.Debug.Assert(start_of_li == i)
                List.children.append(Block(lines[i]))
            } else {
                //  Build a new string containing all child items
                var bAnyBlanks: Bool = false
                var sb: String = ""
                for j in start_of_li ... end_of_li {
                    let l = lines[j]
                    sb.append(l.buf!.substring(from: l.contentStart, for: l.contentLen))
                    sb.append("\n")
                    if lines[j].blockType == BlockType.Blank {
                        bAnyBlanks = true
                    }
                }
                //  Create the item and process child blocks
                let item = Block(type: BlockType.li)
                item.children = BlockProcessor(m, p.m_bMarkdownInHtml, listType).process(sb)
                //  If no blank lines, change all contained paragraphs to plain text
                if !bAnyBlanks {
                    for child in item.children {
                        if child.blockType == BlockType.p {
                            child.blockType = BlockType.span
                        }
                    }
                }
                //  Add the complex item
                List.children.append(item)
            }
            //  Continue processing from end of li
            i = end_of_li
        }
        lines.removeAll()

        //  Continue processing after this item
        return List
    }

}
