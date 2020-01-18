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

struct FencedCodeBlocks {
    private var m: Markdown
    private var p: BlockProcessor

    init(m: Markdown, p: BlockProcessor) {
        self.m = m
        self.p = p
    }

    func process(_ b: Block) -> Bool {
        let delim = p.current

        //  Extract the fence
        p.markPosition()
        while p.current == delim {
            p.skipForward(1)
        }

        let strFence: String! = p.extract()

        //  Must be at least 3 long
        if strFence.count < 3 {
            return false
        }

        //  Rest of line must be blank
        p.skipLinespace()
        if !p.eol {
            return false
        }

        //  Skip the eol and remember start of code
        p.skipEol()
        let startCode: Int = p.position
        //  Find the end fence
        if !p.find(strFence) {
            return false
        }

        //  Character before must be a eol char
        if !p.isLineEnd(p.charAtOffset(-1)) {
            return false
        }

        var endCode: Int = p.position

        //  Skip the fence
        p.skipForward(strFence.count)
        //  Whitespace allowed at end
        p.skipLinespace()
        if !p.eol {
            return false
        }

        //  Create the code block
        b.blockType = BlockType.codeblock
        b.children = []

        //  Remove the trailing line end
        if (p.input.hasSuffix("\r\n")) {
            endCode -= 2
        } else if (p.input.hasSuffix("\n\r")) {
            endCode -= 2
        } else  {
            endCode -= 1
        }

        //  Create the child block with the entire content
        let child = Block()
        child.blockType = BlockType.indent
        child.buf = p.input
        child.contentStart = startCode
        child.contentEnd = endCode
        b.children.append(child)
        return true
    }
}
