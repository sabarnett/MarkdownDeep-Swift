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

class Block : CustomStringConvertible
{

    var blockType: BlockType = BlockType.Blank
    var buf: String?
    var contentStart: Int = 0
    var contentLen: Int = 0
    var lineStart: Int = 0
    var lineLen: Int = 0
    var data: Any?          // content depends on block type
    var children: Array<Block> = []

    init() {
    }

    init(type: BlockType) {
        blockType = type
    }

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

    var description: String {
        get {
            if let text = content {
                return blockType.description + " - " + text
            }

            return blockType.description + " - <null>"
        }
    }

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

    var LineStart: Int
    {
        get
        {
            return lineStart == 0 ? contentStart : lineStart
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

    func renderChildren(_ m: Markdown, _ b: inout String)
    {
        for block in children {
            block.render(m, &b)
        }
    }

    func renderChildrenPlain(_ m: Markdown, _ b: inout String)
    {
        for block in children {
            block.renderPlain(m, &b)
        }
    }

    func resolveHeaderID(_ m: Markdown) -> String!
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

            case BlockType.h1,
                BlockType.h2,
                BlockType.h3,
                BlockType.h4,
                BlockType.h5,
                BlockType.h6:
                if (m.ExtraMode && !m.SafeMode)
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

            case BlockType.hr:
                b.append("<hr />\n")
                return

            case BlockType.user_break:
                return

            case BlockType.ol_li,
                 BlockType.ul_li:
                b.append("<li>")
                m.getSpanFormatter.format(&b, buf!, contentStart, contentLen)
                b.append("</li>\n")

            case BlockType.dd:
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

            case BlockType.dt:
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

            case BlockType.dl:
                b.append("<dl>\n")
                renderChildren(m, &b)
                b.append("</dl>\n")
                return

            case BlockType.html:
                b.append(buf!.substring(from: contentStart, for: contentLen))
                return

            case BlockType.unsafe_html:
                m.htmlEncode(&b, buf!, contentStart, contentLen)
                return

            case BlockType.codeblock:

                // TODO: FormatCodeBlock is a call back and we don't support those yet
//                if (m.FormatCodeBlock != nil)
//                {
//                    var sb = ""
//                    for line in children {
//                        m.htmlEncodeAndConvertTabsToSpaces(&sb, line.buf!, line.contentStart, line.contentLen)
//                        sb.append("\n")
//                    }
//                    b.append(m.FormatCodeBlock(m, sb))
//                }
//                else
//                {
                    b.append("<pre><code>")
                    for line in children {
                        m.htmlEncodeAndConvertTabsToSpaces(&b, line.buf!, line.contentStart, line.contentLen)
                        b.append("\n")
                    }
                    b.append("</code></pre>\n")
//                }
                return;

            case BlockType.quote:
                b.append("<blockquote>\n")
                renderChildren(m, &b)
                b.append("</blockquote>\n")
                return

            case BlockType.li:
                b.append("<li>\n")
                renderChildren(m, &b)
                b.append("</li>\n")
                return

            case BlockType.ol:
                b.append("<ol>\n")
                renderChildren(m, &b)
                b.append("</ol>\n")
                return

            case BlockType.ul:
                b.append("<ul>\n")
                renderChildren(m, &b)
                b.append("</ul>\n")
                return

            case BlockType.HtmlTag:
                if let tag = data as? HtmlTag {
                    // Prepare special tags
                    let name = tag.name.lowercased()
                    if (name == "a")
                    {
                        m.onPrepareLink(tag);
                    }
                    else if (name == "img")
                    {
                        m.onPrepareImage(tag, m.RenderingTitledImage);
                    }

                    tag.renderOpening(&b)
                    b.append("\n")
                    renderChildren(m, &b)
                    tag.renderClosing(&b)
                    b.append("\n")
                }

                return

            case BlockType.Composite,
                 BlockType.footnote:
                renderChildren(m, &b)
                return

            case BlockType.table_spec:
                if let tspec = data as? TableSpec {
                    tspec.render(m, &b)
                }

            case BlockType.p_footnote:
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

            default:
                b.append("<\(blockType.description)>")
                m.getSpanFormatter.format(&b, buf!, contentStart, contentLen)
                b.append("</\(blockType.description)>\n")
        }
    }

    func renderPlain(_ m: Markdown, _ b: inout String)
    {
        switch (blockType)
        {
            case BlockType.Blank:
                return;

            case BlockType.p,
                 BlockType.span:
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
}

