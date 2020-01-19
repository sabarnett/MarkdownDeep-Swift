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

class BlockProcessor : StringScanner {
     var m_markdown: Markdown
     var m_parentType: BlockType!
     var m_bMarkdownInHtml: Bool = false

    init(_ m: Markdown, _ MarkdownInHtml: Bool) {
        m_markdown = m
        m_bMarkdownInHtml = MarkdownInHtml
        m_parentType = BlockType.Blank
        super.init()
    }

    init(_ m: Markdown, _ MarkdownInHtml: Bool, _ parentType: BlockType) {
        m_markdown = m
        m_bMarkdownInHtml = MarkdownInHtml
        m_parentType = parentType
        super.init()
    }

    func process(_ str: String) -> [Block] {
        return scanLines(str)
    }

    private func scanLines(_ str: String) -> [Block] {
        //  Reset string scanner
        reset(str)
        return scanLines()
    }

    func scanLines(_ str: String, _ start: Int, _ len: Int) -> [Block] {
        reset(str, start, len)
        return scanLines()
    }

    private func startTable(_ spec: TableSpec, _ lines: inout [Block]) -> Bool {
        //  Mustn't have more than 1 preceeding line
        if lines.count > 1 {
            return false
        }
        //  Rewind, parse the header row then fast forward back to current pos
        if lines.count == 1 {
            let savepos: Int = position
            position = lines[0].lineStart
            spec.Headers = spec.parseRow(self)
            if spec.Headers.count == 0 {
                return false
            }
            position = savepos
            lines.removeAll()
        }
        //  Parse all rows
        while true {
            let savepos: Int = position
            let row = spec.parseRow(self)
            if row != nil {
                spec.Rows.append(row!)
                continue
            }
            position = savepos
            break
        }
        return true
    }

    private func scanLines() -> [Block] {
        //  The final set of blocks will be collected here
        var blocks: [Block] = []

        //  The current paragraph/list/codeblock etc will be accumulated here
        //  before being collapsed into a block and store in above `blocks` list
        var lines: [Block] = []

        //  Add all blocks
        var prevBlockType: BlockType = BlockType.unsafe_html

        while !eof {
            //  Remember if the previous line was blank
            let bPreviousBlank: Bool = prevBlockType == BlockType.Blank
            //  Get the next block
            let b = evaluateLine()
            prevBlockType = b.blockType

            //  For dd blocks, we need to know if it was preceeded by a blank line
            //  so store that fact as the block's data.
            if b.blockType == BlockType.dd {
                b.data = String(bPreviousBlank)
            }
            
            //  SetExt header?
            if (b.blockType == BlockType.post_h1) || (b.blockType == BlockType.post_h2) {
                if lines.count > 0 {
                    //  Remove the previous line and collapse the current paragraph
                    let prevline = lines.removeLast()
                    collapseLines(&blocks, &lines)
                    //  If previous line was blank,
                    if prevline.blockType != BlockType.Blank {
                        //  Convert the previous line to a heading and add to block list
                        prevline.revertToPlain()
                        prevline.blockType = (b.blockType == BlockType.post_h1 ? BlockType.h1 : BlockType.h2)
                        blocks.append(prevline)
                        continue
                    }
                }
                //  Couldn't apply setext header to a previous line
                if b.blockType == BlockType.post_h1 {
                    //  `===` gets converted to normal paragraph
                    b.revertToPlain()
                    lines.append(b)
                } else {
                    //  `---` gets converted to hr
                    if b.contentLen >= 3 {
                        b.blockType = BlockType.hr
                        blocks.append(b)
                    } else {
                        b.revertToPlain()
                        lines.append(b)
                    }
                }
                continue
            }
            //  Work out the current paragraph type
            let currentBlockType: BlockType = (lines.count > 0 ? lines[0].blockType : BlockType.Blank)

            //  Starting a table?
            if b.blockType == BlockType.table_spec {
                //  Get the table spec, save position
                let spec: TableSpec! = (b.data as? TableSpec)
                let savepos: Int = position
                if !startTable(spec, &lines) {
                    //  Not a table, revert the tablespec row to plain,
                    //  fast forward back to where we were up to and continue
                    //  on as if nothing happened
                    position = savepos
                    b.revertToPlain()
                } else {
                    blocks.append(b)
                    continue
                }
            }
            //  Process this line
            switch b.blockType {
                case BlockType.Blank:
                    switch currentBlockType {
                        case BlockType.Blank:
                            break

                        case BlockType.p:
                            collapseLines(&blocks, &lines)
                             break

                        case BlockType.quote,
                            BlockType.ol_li,
                            BlockType.ul_li,
                            BlockType.dd,
                            BlockType.footnote,
                            BlockType.indent:
                            lines.append(b)

                        default:
                            break
                    }

                case BlockType.p:
                    switch currentBlockType {
                        case BlockType.Blank,
                             BlockType.p:
                            lines.append(b)

                        case BlockType.quote,
                             BlockType.ol_li,
                             BlockType.ul_li,
                             BlockType.dd,
                             BlockType.footnote:
                            let lastItem = lines.count - 1
                            let prevline = lines[lastItem]
                            if prevline.blockType == BlockType.Blank {
                                collapseLines(&blocks, &lines)
                                lines.append(b)
                            } else {
                                lines.append(b)
                            }
                        case BlockType.indent:
                            collapseLines(&blocks, &lines)
                            lines.append(b)
                        default:
                            break
                    }
                case BlockType.indent:
                    switch currentBlockType {
                        case BlockType.Blank:
                            lines.append(b)

                        case BlockType.p,
                             BlockType.quote:
                            let lastItem = lines.count - 1
                            let prevline = lines[lastItem]
                            if prevline.blockType == BlockType.Blank {
                                //  Start a code block after a paragraph
                                collapseLines(&blocks, &lines)
                                lines.append(b)
                            } else {
                                //  indented line in paragraph, just continue it
                                b.revertToPlain()
                                lines.append(b)
                            }
                        case BlockType.ol_li,
                             BlockType.ul_li,
                             BlockType.dd,
                             BlockType.footnote,
                             BlockType.indent:
                            lines.append(b)
                        default:
                            break
                    }

                case BlockType.quote:
                    if currentBlockType != BlockType.quote {
                        collapseLines(&blocks, &lines)
                    }
                    lines.append(b)

                case BlockType.ol_li,
                     BlockType.ul_li:
                    switch currentBlockType {
                        case BlockType.Blank:
                            lines.append(b)

                        case BlockType.p,
                             BlockType.quote:
                            let lastItem = lines.count - 1
                            let prevline = lines[lastItem]

                            if (prevline.blockType == BlockType.Blank) || (m_parentType == BlockType.ol_li) || (m_parentType == BlockType.ul_li) || (m_parentType == BlockType.dd) {
                                //  List starting after blank line after paragraph or quote
                                collapseLines(&blocks, &lines)
                                lines.append(b)
                            } else {
                                //  List's can't start in middle of a paragraph
                                b.revertToPlain()
                                lines.append(b)
                            }

                        case BlockType.ol_li,
                             BlockType.ul_li:
                            if (b.blockType != BlockType.ol_li) && (b.blockType != BlockType.ul_li) {
                                collapseLines(&blocks, &lines)
                            }
                            lines.append(b)

                        case BlockType.dd,
                             BlockType.footnote:
                            if b.blockType != currentBlockType {
                                collapseLines(&blocks, &lines)
                            }
                            lines.append(b)

                        case BlockType.indent:
                            collapseLines(&blocks, &lines)
                            lines.append(b)
                    default:
                        break
                    }

                case BlockType.dd,
                     BlockType.footnote:
                    switch currentBlockType {
                        case BlockType.Blank,
                            BlockType.p,
                            BlockType.dd,
                            BlockType.footnote:
                            collapseLines(&blocks, &lines)
                            lines.append(b)
                        default:
                            b.revertToPlain()
                            lines.append(b)
                    }
                default:
                    collapseLines(&blocks, &lines)
                    blocks.append(b)
            }
        }

        collapseLines(&blocks, &lines)
        if m_markdown.extraMode {
            DefinitionBuilder(m: m_markdown, p: self).buildDefinitionLists(&blocks)
        }
        return blocks
    }

    private func renderLines(_ lines: [Block]) -> String {
        var b = ""
        for l in lines {
            b.append(l.buf!.substring(from: l.contentStart, for: l.contentLen))
            b.append("\n")
        }
        return b
    }

    private func collapseLines(_ blocks: inout [Block], _ lines: inout [Block]) {
        //  Remove trailing blank lines
        while (lines.count > 0) && (lines[lines.count - 1].blockType == BlockType.Blank) {
            lines.removeLast()
        }

        //  Quit if empty
        if lines.count == 0 {
            return
        }

        //  What sort of block?
        switch lines[0].blockType {
            case BlockType.p:
                //  Collapse all lines into a single paragraph
                let para = Block()
                para.blockType = BlockType.p
                para.buf = lines[0].buf
                para.contentStart = lines[0].contentStart
                para.contentEnd = lines[lines.count - 1].contentEnd
                blocks.append(para)
                lines.removeAll()

            case BlockType.quote:
                //  Create a new quote block
                let quote = Block(type: BlockType.quote)
                quote.children = BlockProcessor(m_markdown, m_bMarkdownInHtml, BlockType.quote).process(renderLines(lines))
                lines.removeAll()
                blocks.append(quote)

            case BlockType.ol_li, BlockType.ul_li:
                let list = ListBuilder(m: m_markdown, p: self).build(&lines)
                blocks.append(list)

            case BlockType.dd:
                if blocks.count > 0 {
                    let prev = blocks[blocks.count - 1]

                    switch prev.blockType {
                        case BlockType.p:
                            prev.blockType = BlockType.dt

                        case BlockType.dd:
                            break

                        default:
                            let wrapper = Block()
                            wrapper.blockType = BlockType.dt
                            wrapper.children = []
                            wrapper.children.append(prev)
                            blocks.removeLast()
                            blocks.append(wrapper)
                    }
                }
                let def = DefinitionBuilder(m: m_markdown, p: self).buildDefinition(&lines)
                blocks.append(def)

            case BlockType.footnote:
                let fn = FootnoteHelper(m: m_markdown, p: self).build(&lines)
                m_markdown.addFootnote(fn)

            case BlockType.indent:
                let codeblock = Block(type: BlockType.codeblock)
                //
                //                     if (m_markdown.FormatCodeBlockAttributes != null)
                //                     {
                //                         // Does the line first line look like a syntax specifier
                //                         var firstline = lines[0].Content;
                //                         if (firstline.StartsWith("{{") && firstline.EndsWith("}}"))
                //                         {
                //                             codeblock.data = firstline.Substring(2, firstline.Length - 4);
                //                             lines.RemoveAt(0);
                //                         }
                //                     }
                //
                codeblock.children = []
                for line in lines {
                    codeblock.children.append(line)
                }
                blocks.append(codeblock)
                lines.removeAll()

        default:
            break
        }
    }

    private func evaluateLine() -> Block {
        //  Create a block
        let b: Block = Block()

        //  Store line start
        b.lineStart = position
        b.buf = input

        //  Scan the line
        b.contentStart = position
        b.contentLen = -1
        b.blockType = evaluateLine(b)

        //  If end of line not returned, do it automatically
        if b.contentLen < 0 {
            //  Move to end of line
            skipToEol()
            b.contentLen = position - b.contentStart
        }

        //  Setup line length
        b.lineLen = position - b.lineStart

        //  Next line
        skipEol()

        //  Create block
        return b
    }

    private func evaluateLine(_ b: Block) -> BlockType {
        //  Empty line?
        if eol {
            return BlockType.Blank
        }

        //  Save start of line position
        let line_start: Int = position

        //  ## Heading ##
        var ch = current
        if ch == "#" {
            //  Work out heading level
            var level: Int = 1
            skipForward(1)
            while current == "#" {
                level += 1
                skipForward(1)
            }

            //  Limit of 6
            if level > 6 {
                level = 6
            }

            //  Skip any whitespace
            skipLinespace()

            //  Save start position
            b.contentStart = position

            //  Jump to end
            skipToEol()

            //  In extra mode, check for a trailing HTML ID
            if m_markdown.extraMode && !m_markdown.safeMode {
                var end: Int = position
                let strID: String! = Utils.stripHtmlID(input, b.contentStart, &end)
                if strID != nil {
                    b.data = strID
                    position = end
                }
            }

            //  Rewind over trailing hashes
            while (position > b.contentStart) && (charAtOffset(-1) == "#") {
                skipForward(-1)
            }

            //  Rewind over trailing spaces
            while (position > b.contentStart) && charAtOffset(-1).isWhitespace {
                skipForward(-1)
            }

            //  Create the heading block
            b.contentEnd = position
            skipToEol()

            switch level - 1 {
                case 0: return BlockType.h1
                case 1: return BlockType.h2
                case 2: return BlockType.h3
                case 3: return BlockType.h4
                case 4: return BlockType.h5
                default: return BlockType.h6
            }
        }

        //  Check for entire line as - or = for setext h1 and h2
        if (ch == "-" || ch == "=") {
            //  Skip all matching characters
            while current == ch {
                skipForward(1)
            }

            //  Trailing whitespace allowed
            skipLinespace()

            //  If not at eol, must have found something other than setext header
            if eol {
                return (ch == "=" ? BlockType.post_h1 : BlockType.post_h2)
            }
            position = line_start
        }
        //  MarkdownExtra Table row indicator?
        if m_markdown.extraMode {
            let spec: TableSpec! = TableSpec.parse(self)
            if spec != nil {
                b.data = spec
                return BlockType.table_spec
            }
            position = line_start
        }
        //  Fenced code blocks?
        if m_markdown.extraMode && ((ch == "~") || (ch == "`")) {
            if FencedCodeBlocks(m: m_markdown, p: self).process(b) {
                return b.blockType
            }

            //  Rewind
            position = line_start
        }

        //  Scan the leading whitespace, remembering how many spaces and where the first tab is
        var tabPos: Int = -1
        var leadingSpaces: Int = 0

        while !eol {
            if current == " " {
                if tabPos < 0 {
                    leadingSpaces += 1
                }
            } else if current == "\t" {
                if tabPos < 0 {
                    tabPos = position
                }
            } else {
                //  Something else, get out
                break
            }

            skipForward(1)
        }

        //  Blank line?
        if eol {
            b.contentEnd = b.contentStart
            return BlockType.Blank
        }

        //  4 leading spaces?
        if leadingSpaces >= 4 {
            b.contentStart = line_start + 4
            return BlockType.indent
        }

        //  Tab in the first 4 characters?
        if (tabPos >= 0) && ((tabPos - line_start) < 4) {
            b.contentStart = tabPos + 1
            return BlockType.indent
        }

        //  Treat start of line as after leading whitespace
        b.contentStart = position

        //  Get the next character
        ch = current

        //  Html block?
        if ch == "<" {
            //  Scan html block
            if HtmlScanner(m: m_markdown, p: self).scanHtml(b: b) {
                return b.blockType
            }

            //  Rewind
            position = b.contentStart
        }

        //  Block quotes start with '>' and have one space or one tab following
        if ch == ">" {
            //  Block quote followed by space
            if isLineSpace(charAtOffset(1)) {
                //  Skip it and create quote block
                skipForward(2)
                b.contentStart = position
                return BlockType.quote
            }
            skipForward(1)
            b.contentStart = position
            return BlockType.quote
        }

        //  Horizontal rule - a line consisting of 3 or more '-', '_' or '*' with optional spaces and nothing else
        if (ch == "-") || (ch == "_") || (ch == "*") {
            var count: Int = 0
            while !eol {
                if current == ch {
                    count += 1
                    skipForward(1)
                    continue
                }
                if isLineSpace(current) {
                    skipForward(1)
                    continue
                }
                break
            }

            if eol && (count >= 3) {
                if m_markdown.userBreaks {
                    return BlockType.user_break
                } else {
                    return BlockType.hr
                }
            }
            //  Rewind
            position = b.contentStart
        }
        //  Abbreviation definition?
        if m_markdown.extraMode && (ch == "*") && (charAtOffset(1) == "[") {
            skipForward(2)
            skipLinespace()
            markPosition()

            while !eol && (current != "]") {
                skipForward(1)
            }

            let abbr = extract().trimWhitespace()
            if (current == "]")
                && (charAtOffset(1) == ":")
                && !String.isNullOrEmpty(abbr) {
                skipForward(2)
                skipLinespace()
                markPosition()
                skipToEol()

                let title = extract()
                m_markdown.addAbbreviation(abbr, title!)
                return BlockType.Blank
            }
            position = b.contentStart
        }
        //  Unordered list
        if ((ch == "*") || (ch == "+") || (ch == "-")) && isLineSpace(charAtOffset(1)) {
            //  Skip it
            skipForward(1)
            skipLinespace()
            b.contentStart = position
            return BlockType.ul_li
        }

        //  Definition
        if (ch == ":") && m_markdown.extraMode && isLineSpace(charAtOffset(1)) {
            skipForward(1)
            skipLinespace()
            b.contentStart = position
            return BlockType.dd
        }
        //  Ordered list
        if ch.isNumber {
            //  Ordered list?  A line starting with one or more digits, followed by a '.' and a space or tab
            //  Skip all digits
            skipForward(1)
            while current.isNumber {
                skipForward(1)
            }

            if skipChar(".") && skipLinespace() {
                b.contentStart = position
                return BlockType.ol_li
            }

            position = b.contentStart
        }
        //  Reference link definition?
        if ch == "[" {
            //  Footnote definition?
            if m_markdown.extraMode && (charAtOffset(1) == "^") {
                let savepos = position
                skipForward(2)

                var id: String!
                if skipFootnoteID(&(id)) && skipChar("]") && skipChar(":") {
                    skipLinespace()
                    b.contentStart = position
                    b.data = id
                    return BlockType.footnote
                }
                position = savepos
            }
            //  Parse a link definition
            let l: LinkDefinition! = LinkDefinition.parseLinkDefinition(self, m_markdown.extraMode)

            if l != nil {
                m_markdown.addLinkDefinition(l)
                return BlockType.Blank
            }
        }

        //  Nothing special
        return BlockType.p
    }
}
