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

class Block
{
    var blockType: BlockType = BlockType.Blank
    var buf: String?
    var contentStart: Int = 0
    var contentLen: Int = 0
    var lineStart: Int = 0
    var lineLen: Int = 0
    var data: Any?                      // content depends on block type
    var children: Array<Block> = []


    // MARK:- Constructors and initialisers

    init() { }

    init(type: BlockType) { blockType = type }

    init(_ copyFrom: Block) {
        blockType = copyFrom.blockType
        buf = copyFrom.buf
        contentStart = copyFrom.contentStart
        contentLen = copyFrom.contentLen
        lineLen = copyFrom.lineLen
        data = copyFrom.data
        for child in copyFrom.children {
            children.append(Block(child))
        }
    }

    func copyFrom(other: Block) -> Block
    {
        blockType = other.blockType
        buf = other.buf
        contentStart = other.contentStart
        contentLen = other.contentLen
        lineStart = other.lineStart
        lineLen = other.lineLen
        return self
    }

    // MARK:- public properties

    var content: String?
    {
        get
        {
            switch (blockType)
            {
                case BlockType.codeblock:
                    var s: String = ""
                    for line in children {
                        s.append(contentsOf: line.content!)
                        s.append(contentsOf: "\n")
                    }
                    return s

                default:
                    break
            }

            if (buf==nil) {
                return nil
            }

            return contentStart == -1
                ? buf
                : buf!.substring(from: contentStart, for: contentLen)
        }
    }

    var contentEnd: Int
    {
        get { return contentStart + contentLen; }
        set { contentLen = newValue - contentStart; }
    }

    // Count the leading spaces on a block
    // Used by list item evaluation to determine indent levels
    // irrespective of indent line type.
    var leadingSpaces: Int
    {
        get
        {
            var count = 0

            if let buffer = buf {
                for i in lineStart ... lineStart + lineLen {
                    if buffer.charAt(at: i) != " " {
                        break
                    }
                    count += 1
                }
            }

            return count
        }
    }

    // MARK:- Publically available methods

    /// Render the child objects of this block in HTML format
    /// - Parameters:
    ///   - m: A reference to the Markdown object
    ///   - b: The buffer to append the output to
    func renderChildren(_ m: Markdown, _ b: inout String)
    {
        for block in children {
            block.render(m, &b)
        }
    }

    /// Render the child objects of this block as plain text
    /// - Parameters:
    ///   - m: A reference to the Markdown object
    ///   - b: The buffer to append the output to
    func renderChildrenPlain(_ m: Markdown, _ b: inout String)
    {
        for block in children {
            block.renderPlain(m, &b)
        }
    }

    /// Render this block (and possibly it's children) in HTML format
    /// - Parameters:
    ///   - m: A reference to the Markdown object
    ///   - b: The buffer to ppend the output to
    func render(_ m: Markdown, _ b: inout String)
    {
        switch (blockType)
        {
            case BlockType.Blank:
                return

            case BlockType.p:
                m.getSpanFormatter.formatParagraph(&b, buf!, contentStart,  contentLen)

            case BlockType.span:
                m.getSpanFormatter.format(&b, buf!, contentStart, contentLen);
                b.append("\n")

            case BlockType.h1, BlockType.h2, BlockType.h3,
                BlockType.h4, BlockType.h5, BlockType.h6:
                renderHeading(m: m, b: &b)

            case BlockType.hr:
                b.append("<hr />\n")
                return

            case BlockType.user_break:
                return

            case BlockType.ol_li, BlockType.ul_li:
                renderListItem(m: m, b: &b)

            case BlockType.dd:
                renderDefinitionDescription(m: m, b: &b)

            case BlockType.dt:
                renderDefinitionTerm(m: m, b: &b)

            case BlockType.dl:
                renderDefinitionList(m: m, b: &b)
                return

            case BlockType.html:
                b.append(buf!.substring(from: contentStart, for: contentLen))
                return

            case BlockType.unsafe_html:
                HtmlHelper.htmlEncode(&b, buf!, contentStart, contentLen)
                return

            case BlockType.codeblock:
                renderCodeBlock(m: m, b: &b)
                return

            case BlockType.quote:
                renderBlockQuote(m: m, b: &b)
                return

            case BlockType.li:
                renderChildItems(m: m, b: &b)
                return

            case BlockType.ol:
                renderOrderedList(m: m, b: &b)
                return

            case BlockType.ul:
                renderUnorderedList(m: m, b: &b)
                return

            case BlockType.HtmlTag:
                renderHtmlTag(m: m, b: &b)
                return

            case BlockType.Composite, BlockType.footnote:
                renderChildren(m, &b)
                return

            case BlockType.table_spec:
                if let tspec = data as? TableSpec {
                    tspec.render(m, &b)
                }

            case BlockType.p_footnote:
                renderFootnote(m: m, b: &b)

            default:
                b.append("<\(blockType.description)>")
                m.getSpanFormatter.format(&b, buf!, contentStart, contentLen)
                b.append("</\(blockType.description)>\n")
        }
    }

    /// Render the block (and possibly its children) in plain text
    /// - Parameters:
    ///   - m: A reference to the markdown object
    ///   - b: The buffer to append the output to
    func renderPlain(_ m: Markdown, _ b: inout String)
    {
        switch (blockType)
        {
            case BlockType.Blank:
                return;

            case BlockType.p, BlockType.span:
                m.getSpanFormatter.formatPlain(&b, buf!, contentStart, contentLen)
                b.append(" ")
                break

            case BlockType.h1, BlockType.h2, BlockType.h3,
                BlockType.h4, BlockType.h5, BlockType.h6:
                m.getSpanFormatter.formatPlain(&b, buf!, contentStart, contentLen)
                b.append(" - ")
                break

            case BlockType.ol_li,
                 BlockType.ul_li:
                b.append("* ")
                m.getSpanFormatter.formatPlain(&b, buf!, contentStart, contentLen)
                b.append(" ")

            case BlockType.dd:
                if (children.count != 0)
                {
                    b.append("\n")
                    renderChildrenPlain(m, &b)
                }
                else {
                    m.getSpanFormatter.formatPlain(&b, buf!, contentStart, contentLen)
                }
                break

            case BlockType.dt:

                if (children.count == 0)
                {
                    for l in content!.split(separator: "\n") {
                        let str: String = String(l).trimWhitespace();
                        m.getSpanFormatter.formatPlain(&b, str, 0, str.count)
                    }
                }
                else
                {
                    renderChildrenPlain(m, &b)
                }
                break

            case BlockType.dl:
                renderChildrenPlain(m, &b)
                return

            case BlockType.codeblock:
                for line in children {
                    b.append(line.buf!.substring(from: line.contentStart, for: line.contentLen))
                    b.append(" ")
                }
                return;

            case BlockType.quote,
                 BlockType.li,
                BlockType.ol,
                BlockType.ul,
                BlockType.HtmlTag:
                renderChildrenPlain(m, &b);
                return;
        default:
            break;
        }
    }

    func revertToPlain()
    {
        blockType = BlockType.p;
        contentStart = lineStart;
        contentLen = lineLen;
    }

    // MARK:- Private helper functons

    private func resolveHeaderID(_ m: Markdown) -> String!
    {
        // Already resolved?
        if let resolvedData = data as? String {
            return resolvedData
        }

        // Approach 1 - PHP Markdown Extra style header id
        var end = contentEnd;
        var id: String? = Utils.stripHtmlID(buf!, contentStart, &end);
        if (id != nil)
        {
            contentEnd = end;
        }
        else
        {
            // Approach 2 - pandoc style header id
            id = m.makeUniqueHeaderID(buf!, contentStart, contentLen);
        }

        self.data = id;
        return id;
    }

}

// MARK:- CustomStringConvertible implementaton

extension Block : CustomStringConvertible {
    var description: String {
        get {
            if let text = content {
                return blockType.description + " - " + text
            }

            return blockType.description + " - <null>"
        }
    }
}

// MARK:- Helper methods for rendering content

extension Block {
    private func renderListItem(m: Markdown, b: inout String) {
        b.append("<li>")
        m.getSpanFormatter.format(&b, buf!, contentStart, contentLen)
        b.append("</li>\n")
    }

    private func renderHeading(m: Markdown, b: inout String) {
        if (m.extraMode && !m.safeMode)
        {
            b.append("<" + blockType.description);
            if let hdrId = resolveHeaderID(m) {
                b.append(" id=\"\(hdrId)\">")
            } else {
                b.append(">")
            }
        }
        else
        {
            b.append("<\(blockType.description)>")
        }
        m.getSpanFormatter.format(&b, buf!, contentStart, contentLen)
        b.append("</\(blockType.description)>\n")
    }

    private func renderDefinitionDescription(m: Markdown, b: inout String) {
        b.append("<dd>")
        if (children.count != 0)
        {
            b.append("\n")
            renderChildren(m, &b)
        }
        else {
            m.getSpanFormatter.format(&b, buf!, contentStart, contentLen)
        }
        b.append("</dd>\n")
    }

    private func renderDefinitionTerm(m: Markdown, b: inout String) {
        if (children.count == 0)
        {
            for l in content!.split(separator: "\n")
            {
                b.append("<dt>")
                m.getSpanFormatter.format(&b, String(l).trimWhitespace())
                b.append("</dt>\n")
            }
        }
        else
        {
            b.append("<dt>\n")
            renderChildren(m, &b)
            b.append("</dt>\n")
        }
    }

    private func renderDefinitionList(m: Markdown, b: inout String) {
        b.append("<dl>\n")
        renderChildren(m, &b)
        b.append("</dl>\n")
    }

    private func renderCodeBlock(m: Markdown, b: inout String) {
        b.append("<pre><code>")
        for line in children {
            HtmlHelper.htmlEncodeAndConvertTabsToSpaces(&b, line.buf!, line.contentStart, line.contentLen)
            b.append("\n")
        }
        b.append("</code></pre>\n")
    }

    private func renderBlockQuote(m: Markdown, b: inout String) {
        b.append("<blockquote>\n")
        renderChildren(m, &b)
        b.append("</blockquote>\n")
    }

    private func renderHtmlTag(m: Markdown, b: inout String) {

        if let tag = data as? HtmlTag {
            // Prepare special tags
            let name = tag.name.lowercased()
            if (name == "a")
            {
                m.onPrepareLink(tag);
            }
            else if (name == "img")
            {
                m.onPrepareImage(tag, m.renderingTitledImage);
            }

            tag.renderOpening(&b)
            b.append("\n")
            renderChildren(m, &b)
            tag.renderClosing(&b)
            b.append("\n")
        }
    }

    private func renderChildItems(m: Markdown, b: inout String) {
        b.append("<li>\n")
        renderChildren(m, &b)
        b.append("</li>\n")
    }

    private func renderOrderedList(m: Markdown, b: inout String) {
        b.append("<ol>\n")
        renderChildren(m, &b)
        b.append("</ol>\n")
    }

    private func renderUnorderedList(m: Markdown, b: inout String) {
        b.append("<ul>\n")
        renderChildren(m, &b)
        b.append("</ul>\n")
    }

    private func renderFootnote(m: Markdown, b: inout String) {
        b.append("<p>")
        if (contentLen > 0)
        {
            m.getSpanFormatter.format(&b, buf!, contentStart, contentLen);
            b.append("&nbsp;")
        }

        if let dataString = data as? String {
            b.append(dataString)
        }
        b.append("</p>\n")

    }
}
