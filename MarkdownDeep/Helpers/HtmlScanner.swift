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

struct HtmlScanner {

    private var m: Markdown
    private var p: BlockProcessor

    init(m: Markdown, p: BlockProcessor) {
        self.m = m
        self.p = p
    }

    func scanHtml(b: Block) -> Bool {
        //  Remember start of html
        var posStartPiece: Int = p.position

        //  Parse a HTML tag
        let openingTag: HtmlTag! = HtmlTag.parse(scanner: p)
        if openingTag == nil {
            return false
        }

        //  Closing tag?
        if openingTag.closing {
            return false
        }

        //  Safe mode?
        var bHasUnsafeContent: Bool = false
        if m.SafeMode && !openingTag.isSafe() {
            bHasUnsafeContent = true
        }

        let flags: HtmlTagFlags = openingTag.Flags

        //  Is it a block level tag?
        if !flags.contains(HtmlTagFlags.Block) {
            return false
        }

        //  Closed tag, hr or comment?
        if flags.contains(HtmlTagFlags.NoClosing) || openingTag.closed {
            p.skipLinespace()
            p.skipEol()
            b.contentEnd = p.position
            b.blockType = (bHasUnsafeContent ? BlockType.unsafe_html : BlockType.html)
            return true
        }

        //  Can it also be an inline tag?
        if flags.contains(HtmlTagFlags.Inline) {
            //  Yes, opening tag must be on a line by itself
            p.skipLinespace()
            if !p.eol {
                return false
            }
        }

        //  Head block extraction?
        let bHeadBlock: Bool = m.ExtractHeadBlocks
            && openingTag.name.lowercased() == "head"

        let headStart: Int = p.position

        //  Work out the markdown mode for this element
        if !bHeadBlock && m.ExtraMode {
            let MarkdownMode: MarkdownInHtmlMode! = getMarkdownMode(openingTag)
            if MarkdownMode != MarkdownInHtmlMode.NA {
                return processMarkdownEnabledHtml(b, openingTag, MarkdownMode)
            }
        }

        var childBlocks: [Block] = []
        //  Now capture everything up to the closing tag and put it all in a single HTML block
        var depth: Int = 1
        while !p.eof {
            //  Find next angle bracket
            if !p.find("<") {
                break
            }

            //  Save position of current tag
            let posStartCurrentTag: Int = p.position
            //  Is it a html tag?
            let tag: HtmlTag! = HtmlTag.parse(scanner: p)
            if tag == nil {
                //  Nope, skip it
                p.skipForward(1)
                continue
            }

            //  Safe mode checks
            if m.SafeMode && !tag.isSafe() {
                bHasUnsafeContent = true
            }

            //  Ignore self closing tags
            if tag.closed {
                continue
            }

            //  Markdown enabled content?
            if !bHeadBlock && !tag.closing && m.ExtraMode && !bHasUnsafeContent {
                let MarkdownMode: MarkdownInHtmlMode! = getMarkdownMode(tag)
                if MarkdownMode != MarkdownInHtmlMode.NA {
                    let markdownBlock: Block = Block()
                    if processMarkdownEnabledHtml(markdownBlock, tag, MarkdownMode) {

                        //  Create a block for everything before the markdown tag
                        if posStartCurrentTag > posStartPiece {
                            let htmlBlock: Block = Block()
                            htmlBlock.buf = p.input
                            htmlBlock.blockType = BlockType.html
                            htmlBlock.contentStart = posStartPiece
                            htmlBlock.contentLen = posStartCurrentTag - posStartPiece
                            childBlocks.append(htmlBlock)
                        }
                        //  Add the markdown enabled child block
                        childBlocks.append(markdownBlock)
                        //  Remember start of the next piece
                        posStartPiece = p.position
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
                        p.skipLinespace()
                        p.skipEol()

                        //  If anything unsafe detected, just encode the whole block
                        if bHasUnsafeContent {
                            b.blockType = BlockType.unsafe_html
                            b.contentEnd = p.position
                            return true
                        }
                        //  Did we create any child blocks
                        if childBlocks.count > 0 {
                            //  Create a block for the remainder
                            if p.position > posStartPiece {
                                let htmlBlock: Block = Block()
                                htmlBlock.buf = p.input
                                htmlBlock.blockType = BlockType.html
                                htmlBlock.contentStart = posStartPiece
                                htmlBlock.contentLen = p.position - posStartPiece
                                childBlocks.append(htmlBlock)
                            }
                            //  Return a composite block
                            b.blockType = BlockType.Composite
                            b.contentEnd = p.position
                            b.children = childBlocks
                            return true
                        }

                        //  Extract the head block content
                        if bHeadBlock {
                            let content = substring(p.str, headStart, posStartCurrentTag - headStart, p.end)
                            m.HeadBlockContent = (m.HeadBlockContent ?? "")
                                + content.trimWhitespace() + "\n"
                            b.blockType = BlockType.html
                            b.contentStart = p.position
                            b.contentEnd = p.position
                            b.lineStart = p.position
                            return true
                        }
                        //  Straight html block
                        b.blockType = BlockType.html
                        b.contentEnd = p.position
                        return true
                    }
                } else {
                    depth += 1
                }
            }
        }//  Rewind to just after the tag
        return false
    }

    private func substring(_ str: String, _ start: Int, _ len: Int, _ end: Int) -> String {
        var length = len
        if (start + len) > end {
            length = end - start
        }
        return str.substring(from: start, for: length)
    }

    private func getMarkdownMode(_ tag: HtmlTag!) -> MarkdownInHtmlMode {
        //  Get the markdown attribute
        let strMarkdownMode: String! = tag.attribute(key: "markdown")
        if !m.ExtraMode || strMarkdownMode == nil {
            if p.m_bMarkdownInHtml {
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

    private func processMarkdownEnabledHtml(_ b: Block, _ openingTag: HtmlTag, _ mode: MarkdownInHtmlMode) -> Bool {
        //  Current position is just after the opening tag
        //  Scan until we find matching closing tag
        let inner_pos: Int = p.position
        var depth: Int = 1
        var bHasUnsafeContent: Bool = false

        while !p.eof {
            //  Find next angle bracket
            if !p.find("<") {
                break
            }

            //  Is it a html tag?
            let tagpos: Int = p.position
            let tag: HtmlTag! = HtmlTag.parse(scanner: p)
            if tag == nil {
                //  Nope, skip it
                p.skipForward(1)
                continue
            }

            //  In markdown off mode, we need to check for unsafe tags
            if m.SafeMode && (mode == MarkdownInHtmlMode.Off) && !bHasUnsafeContent {
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
                        p.skipLinespace()
                        p.skipEol()
                        b.blockType = BlockType.HtmlTag
                        b.data = openingTag
                        b.contentEnd = p.position
                        switch mode {
                            case MarkdownInHtmlMode.Span:

                                let span: Block = Block()
                                span.buf = p.input
                                span.blockType = BlockType.span
                                span.contentStart = inner_pos
                                span.contentLen = tagpos - inner_pos
                                b.children = []
                                b.children.append(span)

                            case MarkdownInHtmlMode.Block,
                                 MarkdownInHtmlMode.Deep:
                                //  Scan the internal content
                                let bp = BlockProcessor(m, mode == MarkdownInHtmlMode.Deep)
                                b.children = bp.scanLines(p.input, inner_pos, tagpos - inner_pos)

                            case MarkdownInHtmlMode.Off:
                                if bHasUnsafeContent {
                                    b.blockType = BlockType.unsafe_html
                                    b.contentEnd = p.position
                                } else {
                                    let span: Block = Block()
                                    span.buf = p.input
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

}
