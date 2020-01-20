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

class SpanFormatter : StringScanner {

    var m_Markdown: Markdown
    internal var disableLinks: Bool = false
    var m_Tokens: [Token] = []

    // MARK:- Initiliser(s)

    /// A reference to the owning markdown object is passed incase
    ///  we need to check for formatting options
    ///
    /// - Parameter m: A reference to the main Markdown object
    init(_ m: Markdown) {
        m_Markdown = m
        super.init()
    }

    // MARK:- Public interface

    func formatParagraph(_ dest: inout String, _ str: String, _ start: Int, _ len: Int) {

        //  Parse the string into a list of tokens
        let tokenizer = Tokenizer(m: m_Markdown, p: self)
        tokenizer.tokenize(str, start, len)

        //  Titled image?
        if (m_Tokens.count == 1
            && m_Markdown.htmlClassTitledImages != nil
            && m_Tokens[0].type == TokenType.img) {
            //  Grab the link info
            let li: LinkInfo! = (m_Tokens[0].data as? LinkInfo)
            //  Render the div opening
            dest.append("<div class=\"")
            dest.append(m_Markdown.htmlClassTitledImages)
            dest.append("\">\n")

            //  Render the img
            m_Markdown.renderingTitledImage = true
            render(&dest, str)

            m_Markdown.renderingTitledImage = false
            dest.append("\n")
            //  Render the title
            if let title = li.def.title  {
                if title.count > 0 {
                    dest.append("<p>")
                    Utils.smartHtmlEncodeAmpsAndAngles(&dest, title)
                    dest.append("</p>\n")
                }
            }

            dest.append("</div>\n")
        } else {
            //  Render the paragraph
            dest.append("<p>")
            render(&dest, str)
            dest.append("</p>\n")
        }
    }

    func format(_ dest: inout String, _ str: String) {
        format(&dest, str, 0, str.count)
    }

    // Format a range in an input string and write it to the destination string builder.
    func format(_ dest: inout String, _ str: String, _ start: Int, _ len: Int) {

        //  Parse the string into a list of tokens
        let tokenizer = Tokenizer(m: m_Markdown, p: self)
        tokenizer.tokenize(str, start, len)

        //  Render all tokens
        render(&dest, str)
    }

    func formatPlain(_ dest: inout String, _ str: String, _ start: Int, _ len: Int) {

        //  Parse the string into a list of tokens
        let tokenizer = Tokenizer(m: m_Markdown, p: self)
        tokenizer.tokenize(str, start, len)

        //  Render all tokens
        renderPlain(&dest, str)
    }

    // Format a string and return it as a new string
    //  (used in formatting the text of links)
    func format(_ str: String) -> String {
        var dest = ""
        format(&dest, str, 0, str.count)
        return dest
    }

    func makeID(_ str: String) -> String {
        return makeID(str, 0, str.count)
    }

    func makeID(_ str: String, _ start: Int, _ len: Int) -> String {
        //  Parse the string into a list of tokens
        let tokenizer = Tokenizer(m: m_Markdown, p: self)
        tokenizer.tokenize(str, start, len)

        var sb = ""
        for t in m_Tokens {
            switch t.type {
                case TokenType.Text:
                    sb.append(str.substring(from: t.startOffset, for: t.length))

                case TokenType.link:
                    let li: LinkInfo! = (t.data as? LinkInfo)
                    sb.append(li.linkText)

            default:
                break
            }
        }

        // Clear the token list now it's been proccesses
        m_Tokens.removeAll()

        //  Now clean it using the same rules as pandoc
        super.reset(sb)

        //  Skip everything up to the first letter
        while !eof {
            let ch = current
            if ch.isLetter {
                break
            }

            skipForward(1)

        }

        //  Process all characters
        sb = ""
        while !eof {
            let ch = current
            if (ch.isLetter || ch.isNumber) || (ch == "_") || (ch == "-") || (ch == ".") {
                sb.append(String(ch).lowercased())
            } else if ch == " " {
                sb.append("-")
            } else {
                if isLineEnd(current) {
                    sb.append("-")
                    skipEol()
                    continue
                }
            }
            skipForward(1)
        }

        return sb
    }

    // Render a list of tokens to a destinatino string builder.
    private func render(_ sb: inout String, _ str: String) {
        for t in m_Tokens {
            switch t.type {
                case TokenType.Text:
                    HtmlHelper.htmlEncode(&sb, str, t.startOffset, t.length)
                case TokenType.HtmlTag:
                    Utils.smartHtmlEncodeAmps(&sb, str, t.startOffset, t.length)
                case TokenType.Html,
                     TokenType.opening_mark,
                     TokenType.closing_mark,
                     TokenType.internal_mark:
                    sb.append(str.substring(from: t.startOffset, for: t.length))
                case TokenType.br:
                    sb.append("<br />\n")
                case TokenType.open_em:
                    sb.append("<em>")
                case TokenType.close_em:
                    sb.append("</em>")
                case TokenType.open_strong:
                    sb.append("<strong>")
                case TokenType.close_strong:
                    sb.append("</strong>")
                case TokenType.code_span:
                    sb.append("<code>")
                    HtmlHelper.htmlEncode(&sb, str, t.startOffset, t.length)
                    sb.append("</code>")
                case TokenType.link:
                    if let li = (t.data as? LinkInfo) {
                        let sf = SpanFormatter(m_Markdown)
                        sf.disableLinks = true
                        li.def.renderLink(m_Markdown, &sb, sf.format(li.linkText))
                    }

                case TokenType.img:
                    if let li = (t.data as? LinkInfo) {
                        li.def.renderImg(m_Markdown, &sb, li.linkText)
                    }

            case TokenType.footnote:
                    let r: FootnoteReference! = (t.data as? FootnoteReference)
                    sb.append("<sup id=\"fnref:")
                    sb.append(r.id)
                    sb.append("\"><a href=\"#fn:")
                    sb.append(r.id)
                    sb.append("\" rel=\"footnote\">")
                    sb.append(String(r.index + 1))
                    sb.append("</a></sup>")

                case TokenType.abbreviation:
                    let a: Abbreviation! = (t.data as? Abbreviation)
                    sb.append("<abbr")
                    if (a.title.count > 0) {
                        sb.append(" title=\"")
                        HtmlHelper.htmlEncode(&sb, a.title, 0, a.title.count)
                        sb.append("\"")
                    }

                    sb.append(">")
                    HtmlHelper.htmlEncode(&sb, a.abbr, 0, a.abbr.count)
                    sb.append("</abbr>")
            }
        }

        // Clear the token list now it's been processed
        m_Tokens.removeAll()
    }

    // Render a list of tokens to a destinatino string builder.
    private func renderPlain(_ sb: inout String, _ str: String) {
        for t in m_Tokens {
            switch t.type {
                case TokenType.Text:
                    sb.append(str.substring(from: t.startOffset, for: t.length))

                 case TokenType.HtmlTag,
                     TokenType.Html,
                     TokenType.opening_mark,
                     TokenType.closing_mark,
                     TokenType.internal_mark,
                     TokenType.br,
                     TokenType.open_em,
                     TokenType.close_em,
                     TokenType.open_strong,
                     TokenType.close_strong:
                    break

                case TokenType.code_span:
                    sb.append(str.substring(from: t.startOffset, for: t.length))

                case TokenType.link:
                    if let li = (t.data as? LinkInfo) {
                        sb.append(li.linkText)
                    }

                case TokenType.img:
                    if let li = (t.data as? LinkInfo) {
                        sb.append(li.linkText)
                    }

                case TokenType.footnote,
                     TokenType.abbreviation:
                    break
            }
        }

        // Clear the token list now it's been processed
        m_Tokens.removeAll()

    }
}
