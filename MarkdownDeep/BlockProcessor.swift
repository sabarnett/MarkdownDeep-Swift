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

class BlockProcessor : StringScanner {
     var m_markdown: Markdown
     var m_parentType: BlockType!
     var m_bMarkdownInHtml: Bool = false

    public init(_ m: Markdown, _ MarkdownInHtml: Bool) {
        m_markdown = m
        m_bMarkdownInHtml = MarkdownInHtml
        m_parentType = BlockType.Blank
        super.init()
    }

    internal init(_ m: Markdown, _ MarkdownInHtml: Bool, _ parentType: BlockType) {
        m_markdown = m
        m_bMarkdownInHtml = MarkdownInHtml
        m_parentType = parentType
        super.init()
    }

    internal func process(_ str: String) -> [Block] {
        return scanLines(str)
    }

    internal func scanLines(_ str: String) -> [Block] {
        //  Reset string scanner
        reset(str)
        return scanLines()
    }

    internal func scanLines(_ str: String, _ start: Int, _ len: Int) -> [Block] {
        reset(str, start, len)
        return scanLines()
    }

    internal func startTable(_ spec: TableSpec, _ lines: inout [Block]) -> Bool {
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

    internal func scanLines() -> [Block] {
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
        if m_markdown.ExtraMode {
            buildDefinitionLists(&blocks)
        }
        return blocks
    }

    internal func freeBlocks(_ blocks: inout [Block]) {
        blocks.removeAll()
    }

    internal func renderLines(_ lines: [Block]) -> String {
        var b = ""
        for l in lines {
            b.append(l.buf!.substring(from: l.contentStart, for: l.contentLen))
            b.append("\n")
        }
        return b
    }

    internal func collapseLines(_ blocks: inout [Block], _ lines: inout [Block]) {
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
                freeBlocks(&lines)

            case BlockType.quote:
                //  Create a new quote block
                let quote = Block(type: BlockType.quote)
                quote.children = BlockProcessor(m_markdown, m_bMarkdownInHtml, BlockType.quote).process(renderLines(lines))
                freeBlocks(&lines)
                blocks.append(quote)

            case BlockType.ol_li,
                 BlockType.ul_li:
                blocks.append(buildList(&lines))

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
                blocks.append(buildDefinition(&lines))

            case BlockType.footnote:
                m_markdown.addFootnote(buildFootnote(&lines))

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

     func evaluateLine() -> Block {
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

     func evaluateLine(_ b: Block) -> BlockType {
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
            if m_markdown.ExtraMode && !m_markdown.SafeMode {
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
        if m_markdown.ExtraMode {
            let spec: TableSpec! = TableSpec.parse(self)
            if spec != nil {
                b.data = spec
                return BlockType.table_spec
            }
            position = line_start
        }
        //  Fenced code blocks?
        if m_markdown.ExtraMode && ((ch == "~") || (ch == "`")) {
            if processFencedCodeBlock(b) {
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
            if scanHtml(b) {
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
                if m_markdown.UserBreaks {
                    return BlockType.user_break
                } else {
                    return BlockType.hr
                }
            }
            //  Rewind
            position = b.contentStart
        }
        //  Abbreviation definition?
        if m_markdown.ExtraMode && (ch == "*") && (charAtOffset(1) == "[") {
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
        if (ch == ":") && m_markdown.ExtraMode && isLineSpace(charAtOffset(1)) {
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
            if m_markdown.ExtraMode && (charAtOffset(1) == "^") {
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
            let l: LinkDefinition! = LinkDefinition.parseLinkDefinition(self, m_markdown.ExtraMode)

            if l != nil {
                m_markdown.addLinkDefinition(l)
                return BlockType.Blank
            }
        }

        //  Nothing special
        return BlockType.p
    }

    internal func GetMarkdownMode(_ tag: HtmlTag!) -> MarkdownInHtmlMode {
        //  Get the markdown attribute
        let strMarkdownMode: String! = tag.attribute(key: "markdown")
        if !m_markdown.ExtraMode || strMarkdownMode == nil {
            if m_bMarkdownInHtml {
                return MarkdownInHtmlMode.Deep
            } else {
                return MarkdownInHtmlMode.NA
            }
        }
        //  Remove it
        tag.removeAttribute(key: "markdown")

        //  Parse mode
        if strMarkdownMode == "1" {
            return (tag.Flags.contains(HtmlTagFlags.ContentAsSpan)
                ? MarkdownInHtmlMode.Span
                : MarkdownInHtmlMode.Block)
        }
        if strMarkdownMode == "block" {
            return MarkdownInHtmlMode.Block
        }
        if strMarkdownMode == "deep" {
            return MarkdownInHtmlMode.Deep
        }
        if strMarkdownMode == "span" {
            return MarkdownInHtmlMode.Span
        }
        return MarkdownInHtmlMode.Off
    }

    internal func processMarkdownEnabledHtml(_ b: Block, _ openingTag: HtmlTag, _ mode: MarkdownInHtmlMode) -> Bool {
        //  Current position is just after the opening tag
        //  Scan until we find matching closing tag
        let inner_pos: Int = position
        var depth: Int = 1
        var bHasUnsafeContent: Bool = false

        while !eof {
            //  Find next angle bracket
            if !find("<") {
                break
            }

            //  Is it a html tag?
            let tagpos: Int = position
            let tag: HtmlTag! = HtmlTag.parse(scanner: self)
            if tag == nil {
                //  Nope, skip it
                skipForward(1)
                continue
            }

            //  In markdown off mode, we need to check for unsafe tags
            if m_markdown.SafeMode && (mode == MarkdownInHtmlMode.Off) && !bHasUnsafeContent {
                if !tag.isSafe() {
                    bHasUnsafeContent = true
                }
            }

            //  Ignore self closing tags
            if tag.closed {
                continue
            }

            //  Same tag?
            if tag.name == openingTag.name {
                if tag.closing {
                    depth -= 1
                    if depth == 0 {
                        //  End of tag?
                        skipLinespace()
                        skipEol()
                        b.blockType = BlockType.HtmlTag
                        b.data = openingTag
                        b.contentEnd = position
                        switch mode {
                            case MarkdownInHtmlMode.Span:

                                let span: Block = Block()
                                span.buf = input
                                span.blockType = BlockType.span
                                span.contentStart = inner_pos
                                span.contentLen = tagpos - inner_pos
                                b.children = []
                                b.children.append(span)

                            case MarkdownInHtmlMode.Block,
                                 MarkdownInHtmlMode.Deep:
                                //  Scan the internal content
                                let bp = BlockProcessor(m_markdown, mode == MarkdownInHtmlMode.Deep)
                                b.children = bp.scanLines(input, inner_pos, tagpos - inner_pos)

                            case MarkdownInHtmlMode.Off:
                                if bHasUnsafeContent {
                                    b.blockType = BlockType.unsafe_html
                                    b.contentEnd = position
                                } else {
                                    let span: Block = Block()
                                    span.buf = input
                                    span.blockType = BlockType.html
                                    span.contentStart = inner_pos
                                    span.contentLen = tagpos - inner_pos
                                    b.children = []
                                    b.children.append(span)
                                }
                        default:
                            break
                        }
                        return true
                    }
                } else {
                    depth += 1
                }
            }
        }

        //  Missing closing tag(s).
        return false
    }

    // Scan from the current position to the end of the html section
    internal func scanHtml(_ b: Block) -> Bool {
        //  Remember start of html
        var posStartPiece: Int = self.position

        //  Parse a HTML tag
        let openingTag: HtmlTag! = HtmlTag.parse(scanner: self)
        if openingTag == nil {
            return false
        }

        //  Closing tag?
        if openingTag.closing {
            return false
        }

        //  Safe mode?
        var bHasUnsafeContent: Bool = false
        if m_markdown.SafeMode && !openingTag.isSafe() {
            bHasUnsafeContent = true
        }

        let flags: HtmlTagFlags = openingTag.Flags

        //  Is it a block level tag?
        if !flags.contains(HtmlTagFlags.Block) {
            return false
        }

        //  Closed tag, hr or comment?
        if flags.contains(HtmlTagFlags.NoClosing) || openingTag.closed {
            skipLinespace()
            skipEol()
            b.contentEnd = position
            b.blockType = (bHasUnsafeContent ? BlockType.unsafe_html : BlockType.html)
            return true
        }

        //  Can it also be an inline tag?
        if flags.contains(HtmlTagFlags.Inline) {
            //  Yes, opening tag must be on a line by itself
            skipLinespace()
            if !eol {
                return false
            }
        }

        //  Head block extraction?
        let bHeadBlock: Bool = m_markdown.ExtractHeadBlocks
            && openingTag.name.lowercased() == "head"

        let headStart: Int = self.position

        //  Work out the markdown mode for this element
        if !bHeadBlock && m_markdown.ExtraMode {
            let MarkdownMode: MarkdownInHtmlMode! = self.GetMarkdownMode(openingTag)
            if MarkdownMode != MarkdownInHtmlMode.NA {
                return self.processMarkdownEnabledHtml(b, openingTag, MarkdownMode)
            }
        }

        var childBlocks: [Block] = []
        //  Now capture everything up to the closing tag and put it all in a single HTML block
        var depth: Int = 1
        while !eof {
            //  Find next angle bracket
            if !find("<") {
                break
            }

            //  Save position of current tag
            let posStartCurrentTag: Int = position
            //  Is it a html tag?
            let tag: HtmlTag! = HtmlTag.parse(scanner: self)
            if tag == nil {
                //  Nope, skip it
                skipForward(1)
                continue
            }

            //  Safe mode checks
            if m_markdown.SafeMode && !tag.isSafe() {
                bHasUnsafeContent = true
            }

            //  Ignore self closing tags
            if tag.closed {
                continue
            }

            //  Markdown enabled content?
            if !bHeadBlock && !tag.closing && m_markdown.ExtraMode && !bHasUnsafeContent {
                let MarkdownMode: MarkdownInHtmlMode! = self.GetMarkdownMode(tag)
                if MarkdownMode != MarkdownInHtmlMode.NA {
                    let markdownBlock: Block = Block()
                    if self.processMarkdownEnabledHtml(markdownBlock, tag, MarkdownMode) {

                        //  Create a block for everything before the markdown tag
                        if posStartCurrentTag > posStartPiece {
                            let htmlBlock: Block = Block()
                            htmlBlock.buf = input
                            htmlBlock.blockType = BlockType.html
                            htmlBlock.contentStart = posStartPiece
                            htmlBlock.contentLen = posStartCurrentTag - posStartPiece
                            childBlocks.append(htmlBlock)
                        }
                        //  Add the markdown enabled child block
                        childBlocks.append(markdownBlock)
                        //  Remember start of the next piece
                        posStartPiece = position
                        continue
                    } else {
                        //self.freeBlock(markdownBlock)
                    }
                }
            }
            //  Same tag?
            if tag.name == openingTag.name {
                if tag.closing {
                    depth -= 1
                    if depth == 0 {
                        //  End of tag?
                        skipLinespace()
                        skipEol()

                        //  If anything unsafe detected, just encode the whole block
                        if bHasUnsafeContent {
                            b.blockType = BlockType.unsafe_html
                            b.contentEnd = position
                            return true
                        }
                        //  Did we create any child blocks
                        if childBlocks.count > 0 {
                            //  Create a block for the remainder
                            if position > posStartPiece {
                                let htmlBlock: Block = Block()
                                htmlBlock.buf = input
                                htmlBlock.blockType = BlockType.html
                                htmlBlock.contentStart = posStartPiece
                                htmlBlock.contentLen = position - posStartPiece
                                childBlocks.append(htmlBlock)
                            }
                            //  Return a composite block
                            b.blockType = BlockType.Composite
                            b.contentEnd = position
                            b.children = childBlocks
                            return true
                        }

                        //  Extract the head block content
                        if bHeadBlock {
                            let content = self.substring(headStart, posStartCurrentTag - headStart)
                            m_markdown.HeadBlockContent = (m_markdown.HeadBlockContent ?? "")
                                + content.trimWhitespace() + "\n"
                            b.blockType = BlockType.html
                            b.contentStart = position
                            b.contentEnd = position
                            b.lineStart = position
                            return true
                        }
                        //  Straight html block
                        b.blockType = BlockType.html
                        b.contentEnd = position
                        return true
                    }
                } else {
                    depth += 1
                }
            }
        }//  Rewind to just after the tag
        return false
    }

    // * Spacing
    //          *
    //          * 1-3 spaces - Promote to indented if more spaces than original item
    //          *
    //
    //
    //          * BuildList - build a single <ol> or <ul> list
    private func buildList(_ lines: inout [Block]) -> Block {
        //  What sort of list are we dealing with
        let listType: BlockType! = lines[0].blockType
        //System.Diagnostics.Debug.Assert((listType == BlockType.ul_li) | (listType == BlockType.ol_li))
        //  Preprocess
        //  1. Collapse all plain lines (ie: handle hardwrapped lines)
        //  2. Promote any unindented lines that have more leading space
        //     than the original list item to indented, including leading
        //     special chars
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

//            System.Diagnostics.Debug.Assert((lines[i].blockType == BlockType.ul_li) | (lines[i].blockType == BlockType.ol_li))
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
                item.children = BlockProcessor(m_markdown, m_bMarkdownInHtml, listType).process(sb)
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
        freeBlocks(&lines)
        lines.removeAll()

        //  Continue processing after this item
        return List
    }

    // * BuildDefinition - build a single <dd> item
    private func buildDefinition(_ lines: inout [Block]) -> Block {
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
        item.children = BlockProcessor(m_markdown, m_bMarkdownInHtml, BlockType.dd).process(sb)
        freeBlocks(&lines)
        lines = []

        //  Continue processing after this item
        return item
    }

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

    private func buildFootnote(_ lines: inout [Block]) -> Block {
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
        item.children = BlockProcessor(m_markdown, m_bMarkdownInHtml, BlockType.footnote).process(sb)
        freeBlocks(&lines)
        lines.removeAll()

        //  Continue processing after this item
        return item
    }

     func processFencedCodeBlock(_ b: Block) -> Bool {
        let delim = current

        //  Extract the fence
        markPosition()
        while current == delim {
            skipForward(1)
        }

        let strFence: String! = extract()

        //  Must be at least 3 long
        if strFence.count < 3 {
            return false
        }

        //  Rest of line must be blank
        skipLinespace()
        if !eol {
            return false
        }

        //  Skip the eol and remember start of code
        skipEol()
        let startCode: Int = position
        //  Find the end fence
        if !find(strFence) {
            return false
        }

        //  Character before must be a eol char
        if !isLineEnd(charAtOffset(-1)) {
            return false
        }

        var endCode: Int = position

        //  Skip the fence
        skipForward(strFence.count)
        //  Whitespace allowed at end
        skipLinespace()
        if !eol {
            return false
        }

        //  Create the code block
        b.blockType = BlockType.codeblock
        b.children = []

        //  Remove the trailing line end
        if (input.hasSuffix("\r\n")) {
            endCode -= 2
        } else if (input.hasSuffix("\n\r")) {
            endCode -= 2
        } else  {
            endCode -= 1
        }

        //  Create the child block with the entire content
        let child = Block()
        child.blockType = BlockType.indent
        child.buf = input
        child.contentStart = startCode
        child.contentEnd = endCode
        b.children.append(child)
        return true
    }

    internal enum MarkdownInHtmlMode {
        case NA
        case Block
        case Span
        case Deep
        case Off
    }
}

