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

struct DefinitionBuilder {
    private var m: Markdown
    private var p: BlockProcessor

    init(m: Markdown, p: BlockProcessor) {
        self.m = m
        self.p = p
    }

    /// Builds a definition list definition - build a single <dd> item
    func buildDefinition(_ lines: inout [Block]) -> Block {
        //  Collapse all plain lines (ie: handle hardwrapped lines)
        var i = 0
        while (i < lines.count) {
            i += 1
            if (i == lines.count) {
                break
            }

            //  Join plain paragraphs
            if (lines[i].blockType == BlockType.p) && ((lines[i - 1].blockType == BlockType.p) || (lines[i - 1].blockType == BlockType.dd)) {
                lines[i - 1].contentEnd = lines[i].contentEnd

                lines.remove(at: i)
                i -= 1
                continue
            }
        }
        //  Single line definition
        let bPreceededByBlank: Bool = Bool(lines[0].data as! String)!
        if (lines.count == 1) && !bPreceededByBlank {
            let ret = lines[0]
            lines.removeAll()
            return ret
        }

        //  Build a new string containing all child items
        var sb: String = ""
        for i in 0 ... lines.count - 1 {
            let l = lines[i]
            sb.append(l.buf!.substring(from: l.contentStart, for: l.contentLen))
            sb.append("\n")
        }

        //  Create the item and process child blocks
        let item = Block()
        item.blockType = BlockType.dd
        item.children = BlockProcessor(m, p.m_bMarkdownInHtml, BlockType.dd).process(sb)
        lines.removeAll()

        //  Continue processing after this item
        return item
    }

    /// Builds a definition list
    func buildDefinitionLists(_ blocks: inout [Block]) {
        var currentList: Block! = nil
        var i = -1
        while i < blocks.count - 1 {
            i += 1
            switch blocks[i].blockType {
                case BlockType.dt,
                     BlockType.dd:
                    if currentList == nil {
                        currentList = Block()
                        currentList.blockType = BlockType.dl
                        currentList.children = []
                        blocks.insert(currentList, at: i)
                        i += 1
                    }
                    currentList.children.append(blocks[i])
                    blocks.remove(at: i)
                    i -= 1
                default:
                    currentList = nil
            }
        }
    }

}
