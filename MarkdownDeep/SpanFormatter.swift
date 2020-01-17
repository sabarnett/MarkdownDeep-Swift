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

class SpanFormatter : StringScanner {

    var m_Markdown: Markdown
    internal var disableLinks: Bool = false
    var m_Tokens: [Token] = []

    // Constructor
    //  A reference to the owning markdown object is passed incase
    //  we need to check for formatting options
    init(_ m: Markdown) {
        m_Markdown = m
        super.init()
    }

    func formatParagraph(_ dest: inout String, _ str: String, _ start: Int, _ len: Int) {

        //  Parse the string into a list of tokens
        tokenize(str, start, len)

        //  Titled image?
        if (m_Tokens.count == 1
            && m_Markdown.HtmlClassTitledImages != nil
            && m_Tokens[0].type == TokenType.img) {
            //  Grab the link info
            let li: LinkInfo! = (m_Tokens[0].data as? LinkInfo)
            //  Render the div opening
            dest.append("<div class=\"")
            dest.append(m_Markdown.HtmlClassTitledImages)
            dest.append("\">\n")

            //  Render the img
            m_Markdown.RenderingTitledImage = true
            render(&dest, str)

            m_Markdown.RenderingTitledImage = false
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
        tokenize(str, start, len)

        //  Render all tokens
        render(&dest, str)
    }

    func formatPlain(_ dest: inout String, _ str: String, _ start: Int, _ len: Int) {

        //  Parse the string into a list of tokens
        tokenize(str, start, len)

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
        tokenize(str, start, len)

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
            freeToken(t)
        }
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
                    m_Markdown.htmlEncode(&sb, str, t.startOffset, t.length)
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
                    m_Markdown.htmlEncode(&sb, str, t.startOffset, t.length)
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
                        m_Markdown.htmlEncode(&sb, a.title, 0, a.title.count)
                        sb.append("\"")
                    }

                    sb.append(">")
                    m_Markdown.htmlEncode(&sb, a.abbr, 0, a.abbr.count)
                    sb.append("</abbr>")
            }
            freeToken(t)
        }
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

            freeToken(t)
        }
    }

    // Scan the input string, creating tokens for anything special
    private func tokenize(_ str: String, _ start: Int, _ len: Int) {
        //  Prepare
        super.reset(str, start, len)

        m_Tokens.removeAll()
        var emphasis_marks: [Token] = []
        let Abbreviations: [Abbreviation] = m_Markdown.getAbbreviations()
        let ExtraMode: Bool = m_Markdown.ExtraMode

        //  Scan string
        var start_text_token: Int = position
        while !eof {
            let end_text_token: Int = position

            //  Work out token
            var token: Token! = nil
            switch current {
                case "*", "_":
                    token = createEmphasisMark()
                    if token != nil {
                        //  Store marks in a separate list the we'll resolve later
                        switch token.type {
                            case TokenType.internal_mark,
                                 TokenType.opening_mark,
                                 TokenType.closing_mark:
                                emphasis_marks.append(token)
                        default:
                            break
                        }
                    }
                case "`":
                    token = processCodeSpan()

                case "[", "!":
                    //  Process link reference
                    let linkpos: Int = position
                    token = processLinkOrImageOrFootnote()
                    
                    //  Rewind if invalid syntax
                    //  (the '[' or '!' will be treated as a regular character and processed below)
                    if token == nil {
                        position = linkpos
                    }

                case "<":
                    //  Is it a valid html tag?
                    let save: Int = position
                    let tag: HtmlTag! = HtmlTag.parse(scanner: self)
                    if tag != nil {
                        if !m_Markdown.SafeMode || tag.isSafe() {
                            //  Yes, create a token for it
                            token = createToken(TokenType.HtmlTag, save, position - save)
                        } else {
                            //  No, rewrite and encode it
                            position = save
                        }
                    } else {
                        //  No, rewind and check if it's a valid autolink eg: <google.com>
                        position = save
                        token = processAutoLink()
                        if token == nil {
                            position = save
                        }
                    }

            case "&":
                //  Is it a valid html entity
                let save: Int = position
                var unused: String! = nil
                if skipHtmlEntity(&unused) {
                    //  Yes, create a token for it
                    token = createToken(TokenType.Html, save, position - save)
                }

            case " ":
                    //  Check for double space at end of a line
                    if (charAtOffset(1) == " ") && isLineEnd(charAtOffset(2)) {
                        //  Yes, skip it
                        skipForward(2)
                        //  Don't put br's at the end of a paragraph
                        if !eof {
                            skipEol()
                            token = createToken(TokenType.br, end_text_token, 0)
                        }
                    }
                case "\\":
                    //  Special handling for escaping <autolinks>
                    //
                    //                         if (CharAtOffset(1) == '<')
                    //                         {
                    //                             // Is it an autolink?
                    //                             int savepos = position;
                    //                             SkipForward(1);
                    //                             bool AutoLink = ProcessAutoLink() != null;
                    //                             position = savepos;
                    //
                    //                             if (AutoLink)
                    //                             {
                    //                                 token = CreateToken(TokenType.Text, position + 1, 1);
                    //                                 SkipForward(2);
                    //                             }
                    //                         }
                    //                         else
                    //
                    //  Check followed by an escapable character
                    if Utils.isEscapableChar(charAtOffset(1), ExtraMode) {
                        token = createToken(TokenType.Text, position + 1, 1)
                        skipForward(2)
                    }
            default:
                break
            }

            //  Look for abbreviations.

            // SAB Never finds abbreviations! Is skipString working???
            let ch = charAtOffset(-1)
            if (token == nil) && Abbreviations.count > 0 &&
                !(ch.isLetter || ch.isNumber) {
                let savepos = position
                for abbr in Abbreviations {
                    if skipString(abbr.abbr) {
                        let chr = current
                        if !(chr.isLetter || chr.isNumber) {
                            token = createToken(TokenType.abbreviation, abbr)
                            break
                        }

                    }
                    position = savepos
                }
            }

            //  If token found, append any preceeding text and the new token to the token list
            if token != nil {
                //  Create a token for everything up to the special character
                if end_text_token > start_text_token {
                    m_Tokens.append(createToken(TokenType.Text, start_text_token, end_text_token - start_text_token))
                }

                //  Add the new token
                m_Tokens.append(token)
                //  Remember where the next text token starts
                start_text_token = position
            } else {
                //  Skip a single character and keep looking
                skipForward(1)
            }
        }

        //  Append a token for any trailing text after the last token.
        if position > start_text_token {
            m_Tokens.append(createToken(TokenType.Text, start_text_token, position - start_text_token))
        }
        //  Do we need to resolve and emphasis marks?
        if emphasis_marks.count > 0 {
            resolveEmphasisMarks(&m_Tokens, &emphasis_marks)
        }
        //  Done!
        return
    }

    private func isEmphasisChar(_ ch: Character) -> Bool {
        return (ch == "_") || (ch == "*")
    }

    // * Resolving emphasis tokens is a two part process
    //          *
    //          * 1. Find all valid sequences of * and _ and create `mark` tokens for them
    //          *        this is done by CreateEmphasisMarks during the initial character scan
    //          *        done by Tokenize
    //          *
    //          * 2. Looks at all these emphasis marks and tries to pair them up
    //          *        to make the actual <em> and <strong> tokens
    //          *
    //          * Any unresolved emphasis marks are rendered unaltered as * or _
    //
    //  Create emphasis mark for sequences of '*' and '_' (part 1)
    private func createEmphasisMark() -> Token! {
        //  Capture current state
        let ch = current
        //let altch = (ch == "*" ? "_" : "*")
        let savepos: Int = position

        //  Check for a consecutive sequence of just '_' and '*'

        if bof || charAtOffset(-1).isWhitespace {
            while isEmphasisChar(current) {
                skipForward(1)
            }

            if eof || current.isWhitespace {
                return Token(TokenType.Html, savepos, position - savepos)
            }
            //  Rewind
            position = savepos
        }

        //  Scan backwards and see if we have space before
        while isEmphasisChar(charAtOffset(-1)) {
            skipForward(-1)
        }

        let bSpaceBefore: Bool = bof || charAtOffset(-1).isWhitespace
        position = savepos

        //  Count how many matching emphasis characters
        while current == ch {
            skipForward(1)
        }

        let count: Int = position - savepos
        //  Scan forwards and see if we have space after
        while isEmphasisChar(charAtOffset(1)) {
            skipForward(1)
        }

        let bSpaceAfter: Bool = eof || current.isWhitespace
        position = savepos + count

        if bSpaceBefore {
            return createToken(TokenType.opening_mark, savepos, position - savepos)
        }

        if bSpaceAfter {
            return createToken(TokenType.closing_mark, savepos, position - savepos)
        }

        if m_Markdown.ExtraMode
            && (ch == "_")
            && (current.isLetter || current.isNumber) {
            return nil
        }

        return createToken(TokenType.internal_mark, savepos, position - savepos)
    }

    // Split mark token
    @discardableResult
    private func splitMarkToken(_ tokens: inout [Token], _ marks: inout [Token], _ token: Token, _ position: Int) -> Token! {

        //  Create the new rhs token
        let tokenRhs: Token! = createToken(token.type, token.startOffset + position, token.length - position)

        //  Adjust down the length of this token
        token.length = position

        let marksTokenIndex = marks.firstIndex { (atoken) -> Bool in
            return atoken == token
        } ?? -1

        let tokensTokenIndex = tokens.firstIndex { (atoken) -> Bool in
            return atoken == token
        } ?? -1

        //  Insert the new token into each of the parent collections
        marks.insert(tokenRhs, at: marksTokenIndex + 1)
        tokens.insert(tokenRhs, at: tokensTokenIndex + 1)

        //  Return the new token
        return tokenRhs
    }

    // Resolve emphasis marks (part 2)
    private func resolveEmphasisMarks(_ tokens: inout [Token], _ marks: inout [Token]) {
        var bContinue: Bool = true
        while bContinue {
            bContinue = false
            var i: Int = 0
            while (i < marks.count ) {
                if (i == marks.count) {
                    break
                }
                
                //  Get the next opening or internal mark
                var opening_mark: Token = marks[i]
                if opening_mark.type != TokenType.opening_mark && opening_mark.type != TokenType.internal_mark {
                    i += 1
                    continue
                }
                //  Look for a matching closin mark
                for j in i + 1 ..< marks.count {
                    //  Get the next closing or internal mark
                    let closing_mark: Token = marks[j]
                    if (closing_mark.type != TokenType.closing_mark) && (closing_mark.type != TokenType.internal_mark) {
                        break
                    }

                    //  Ignore if different type (ie: `*` vs `_`)
                    if input.charAt(at: opening_mark.startOffset) !=
                        input.charAt(at: closing_mark.startOffset) {
                        continue
                    }


                    //  strong or em?
                    var style: Int = min(opening_mark.length, closing_mark.length)
                    //  Triple or more on both ends?
                    if style >= 3 {
                        style = ((style % 2) == 1 ? 1 : 2)
                    }
                    //  Split the opening mark, keeping the RHS
                    if opening_mark.length > style {
                        opening_mark = splitMarkToken(&tokens, &marks, opening_mark, opening_mark.length - style)
                        i -= 1
                    }
                    //  Split the closing mark, keeping the LHS
                    if closing_mark.length > style {
                        splitMarkToken(&tokens, &marks, closing_mark, style)
                    }

                    //  Connect them
                    opening_mark.type = (style == 1 ? TokenType.open_em : TokenType.open_strong)
                    closing_mark.type = (style == 1 ? TokenType.close_em : TokenType.close_strong)

                    //  Remove the matched marks
                    if let openingIndex = marks.firstIndex(where: { (aToken) -> Bool in
                        return aToken == opening_mark
                    }) {
                        marks.remove(at: openingIndex)
                    }

                    if let closingIndex = marks.firstIndex(where: { (aToken) -> Bool in
                        return aToken == closing_mark
                    }) {
                        marks.remove(at: closingIndex)
                    }

                    bContinue = true
                    break
                }

                i += 1
            }
        }

    }

    // Resolve emphasis marks (part 2)
    private func resolveEmphasisMarks_classic(_ tokens: inout [Token], _ marks: inout [Token]) {
        //  First pass, do <strong>
        var i = 0
        while (i < marks.count) {
            //  Get the next opening or internal mark
            let opening_mark: Token = marks[i]
            if (opening_mark.type != TokenType.opening_mark && opening_mark.type != TokenType.internal_mark) {
                i += 1
                continue
            }

            if opening_mark.length < 2 {
                i += 1
                continue
            }

            //  Look for a matching closing mark
            for j in i+1..<marks.count {
                //  Get the next closing or internal mark
                var closing_mark: Token! = marks[j]
                if (closing_mark.type != TokenType.closing_mark && closing_mark.type != TokenType.internal_mark) {
                    continue
                }

                //  Ignore if different type (ie: `*` vs `_`)
                if input.charAt(at: opening_mark.startOffset) != input.charAt(at: closing_mark.startOffset) {
                    continue
                }

                //  Must be at least two
                if closing_mark.length < 2 {
                    continue
                }

                //  Split the opening mark, keeping the LHS
                if opening_mark.length > 2 {
                    splitMarkToken(&tokens, &marks, opening_mark, 2)
                }

                //  Split the closing mark, keeping the RHS
                if closing_mark.length > 2 {
                    closing_mark = splitMarkToken(&tokens, &marks, closing_mark, closing_mark.length - 2)
                }

                //  Connect them
                opening_mark.type = TokenType.open_strong
                closing_mark.type = TokenType.close_strong

                //  Continue after the closing mark
                i = marks.firstIndex(where: { (aToken) -> Bool in
                    return aToken == closing_mark
                }) ?? 0
                break
            }

            i += 1
        }

        //  Second pass, do <em>
        i = 0
        while (i < marks.count) {
            //  Get the next opening or internal mark
            let opening_mark: Token! = marks[i]
            if (opening_mark.type != TokenType.opening_mark) && (opening_mark.type != TokenType.internal_mark) {
                continue
            }
            //  Look for a matching closing mark
            for j in i+1..<marks.count {
                //  Get the next closing or internal mark
                var closing_mark: Token! = marks[j]
                if (closing_mark.type != TokenType.closing_mark && closing_mark.type != TokenType.internal_mark) {
                    continue
                }

                //  Ignore if different type (ie: `*` vs `_`)
                if input.charAt(at: opening_mark.startOffset) != input.charAt(at: closing_mark.startOffset) {
                    continue
                }

                //  Split the opening mark, keeping the LHS
                if opening_mark.length > 1 {
                    splitMarkToken(&tokens, &marks, opening_mark, 1)
                }
                //  Split the closing mark, keeping the RHS
                if closing_mark.length > 1 {
                    closing_mark = splitMarkToken(&tokens, &marks, closing_mark, closing_mark.length - 1)
                }

                //  Connect them
                opening_mark.type = TokenType.open_em
                closing_mark.type = TokenType.close_em

                //  Continue after the closing mark
                i = marks.firstIndex(where: { (aToken) -> Bool in
                    return aToken == closing_mark
                }) ?? 0
                break
            }

            i += 1
        }
    }

    // Process '*', '**' or '_', '__'
    //  This is horrible and probably much better done through regex, but I'm stubborn.
    //  For normal cases this routine works as expected.  For unusual cases (eg: overlapped
    //  strong and emphasis blocks), the behaviour is probably not the same as the original
    //  markdown scanner.
    //
    //         public Token ProcessEmphasisOld(ref Token prev_single, ref Token prev_double)
    //         {
    //             // Check whitespace before/after
    //             bool bSpaceBefore = !bof && IsLineSpace(CharAtOffset(-1));
    //             bool bSpaceAfter = IsLineSpace(CharAtOffset(1));
    //
    //             // Ignore if surrounded by whitespace
    //             if (bSpaceBefore && bSpaceAfter)
    //             {
    //                 return null;
    //             }
    //
    //             // Save the current character and skip it
    //             char ch = current;
    //             Skip(1);
    //
    //             // Do we have a previous matching single star?
    //             if (!bSpaceBefore && prev_single != null)
    //             {
    //                 // Yes, match them...
    //                 prev_single.type = TokenType.open_em;
    //                 prev_single = null;
    //                 return CreateToken(TokenType.close_em, position - 1, 1);
    //             }
    //
    //             // Is this a double star/under
    //             if (current == ch)
    //             {
    //                 // Skip second character
    //                 Skip(1);
    //
    //                 // Space after?
    //                 bSpaceAfter = IsLineSpace(current);
    //
    //                 // Space both sides?
    //                 if (bSpaceBefore && bSpaceAfter)
    //                 {
    //                     // Ignore it
    //                     return CreateToken(TokenType.Text, position - 2, 2);
    //                 }
    //
    //                 // Do we have a previous matching double
    //                 if (!bSpaceBefore && prev_double != null)
    //                 {
    //                     // Yes, match them
    //                     prev_double.type = TokenType.open_strong;
    //                     prev_double = null;
    //                     return CreateToken(TokenType.close_strong, position - 2, 2);
    //                 }
    //
    //                 if (!bSpaceAfter)
    //                 {
    //                     // Opening double star
    //                     prev_double = CreateToken(TokenType.Text, position - 2, 2);
    //                     return prev_double;
    //                 }
    //
    //                 // Ignore it
    //                 return CreateToken(TokenType.Text, position - 2, 2);
    //             }
    //
    //             // If there's a space before, we can open em
    //             if (!bSpaceAfter)
    //             {
    //                 // Opening single star
    //                 prev_single = CreateToken(TokenType.Text, position - 1, 1);
    //                 return prev_single;
    //             }
    //
    //             // Ignore
    //             Skip(-1);
    //             return null;
    //         }
    //
    //  Process auto links eg: <google.com>
    private func processAutoLink() -> Token! {
        if disableLinks {
            return nil
        }
        //  Skip the angle bracket and remember the start
        skipForward(1)
        markPosition()
        let ExtraMode: Bool = m_Markdown.ExtraMode
        //  Allow anything up to the closing angle, watch for escapable characters
        while !eof {
            let ch: Character = current
            //  No whitespace allowed
            if ch.isWhitespace {
                break
            }
            //  End found?
            if ch == ">" {
                var url: String! = Utils.unescapeString(extract(), ExtraMode)
                var li: LinkInfo! = nil
                if Utils.isEmailAddress(url) {
                    var link_text: String
                    if url.lowercased().hasPrefix("mailto:") {
                        link_text = url.right(from: 7)
                    } else {
                        link_text = url
                        url = "mailto:" + url
                    }

                    li = LinkInfo(linkDef: LinkDefinition("auto", url, nil), linkText: link_text)
                } else {
                    if Utils.isWebAddress(url) {
                        li = LinkInfo(linkDef: LinkDefinition("auto", url, nil), linkText: url)
                    }
                }
                if li != nil {
                    skipForward(1)
                    return createToken(TokenType.link, li!)
                }
                return nil
            }
            self.skipEscapableChar(ExtraMode)
        }//  Didn't work
        return nil
    }

    // Process [link] and ![image] directives
    private func processLinkOrImageOrFootnote() -> Token! {
        //  Link or image?
        let token_type: TokenType = (skipChar("!") ? TokenType.img : TokenType.link)
        //  Opening '['
        if !skipChar("[") {
            return nil
        }
        //  Is it a foonote?
        var savepos = position
        if m_Markdown.ExtraMode && token_type == TokenType.link && skipChar("^") {
            skipLinespace()

            //  Parse it
            var id: String!
            if skipFootnoteID(&(id)) && skipChar("]") {
                //  Look it up and create footnote reference token
                let footnote_index: Int = m_Markdown.claimFootnote(id)
                if footnote_index >= 0 {
                    //  Yes it's a footnote
                    return createToken(TokenType.footnote, FootnoteReference(index: footnote_index, id: id))
                }
            }
            //  Rewind
            position = savepos
        }

        if disableLinks && token_type == TokenType.link {
            return nil
        }

        let ExtraMode: Bool = m_Markdown.ExtraMode
        //  Find the closing square bracket, allowing for nesting, watching for
        //  escapable characters
        markPosition()
        var depth: Int = 1
        while !eof {
            let ch: Character = current
            if ch == "[" {
                depth += 1
            } else {
                if ch == "]" {
                    depth -= 1
                    if depth == 0 {
                        break
                    }
                }
            }
            self.skipEscapableChar(ExtraMode)
        }

        //  Quit if end
        if eof {
            return nil
        }

        //  Get the link text and unescape it
        let link_text: String! = Utils.unescapeString(extract(), ExtraMode)

        //  The closing ']'
        skipForward(1)

        //  Save position in case we need to rewind
        savepos = position

        //  Inline links must follow immediately
        if skipChar("(") {
            //  Extract the url and title
            let link_def = LinkDefinition.parseLinkTarget(self, nil, m_Markdown.ExtraMode)
            if link_def == nil {
                return nil
            }
            //  Closing ')'
            skipWhitespace()
            if !skipChar(")") {
                return nil
            }
            //  Create the token
            return createToken(token_type, LinkInfo(linkDef: link_def!, linkText: link_text))
        }

        //  Optional space or tab
        if !skipChar(" ") {
            skipChar("\t")
        }
        //  If there's line end, we're allow it and as must line space as we want
        //  before the link id.
        if eol {
            skipEol()
            skipLinespace()
        }

        //  Reference link?
        var link_id: String! = nil
        if current == "[" {
            //  Skip the opening '['
            skipForward(1)
            //  Find the start/end of the id
            markPosition()
            if !find("]") {
                return nil
            }
            //  Extract the id
            link_id = extract()
            //  Skip closing ']'
            skipForward(1)
        } else {
            //  Rewind to just after the closing ']'
            position = savepos
        }

        //  Link id not specified?
        if !(link_id != nil && link_id.count > 0) {
            //  Use the link text (implicit reference link)
            link_id = Utils.normalizeLineEnds(link_text)

            //  If the link text has carriage returns, normalize
            //  to spaces
            //if !Object.ReferenceEquals(link_id, link_text) {
                while link_id.indexOf(str: " \n") >= 0 {
                    link_id = link_id.replacingOccurrences(of: " \n", with: "\n")
                }
                link_id = link_id.replacingOccurrences(of: "\n", with: " ")
            //}
        }
        //  Find the link definition abort if not defined
        let def = m_Markdown.getLinkDefinition(link_id)
        if def == nil {
            return nil
        }
        //  Create a token
        return createToken(token_type, LinkInfo(linkDef: def!, linkText: link_text))
    }

    // Process a ``` code span ```
    private func processCodeSpan() -> Token! {
        let start: Int = position
        //  Count leading ticks
        var tickcount: Int = 0
        while skipChar("`") {
            tickcount += 1
        }

        //  Skip optional leading space...
        skipWhitespace()

        //  End?
        if eof {
            return createToken(TokenType.Text, start, position - start)
        }

        let startofcode: Int = position

        //  Find closing ticks
        if !find(substring(start, tickcount)) {
            return createToken(TokenType.Text, start, position - start)
        }

        //  Save end position before backing up over trailing whitespace
        let endpos: Int = position + tickcount
        while charAtOffset(-1).isWhitespace {
            skipForward(-1)

        }

        //  Create the token, move back to the end and we're done
        let ret = createToken(TokenType.code_span, startofcode, position - startofcode)
        position = endpos
        return ret
    }

    // #region Token Pooling
    //  CreateToken - create or re-use a token object
    internal func createToken(_ type: TokenType, _ startOffset: Int, _ length: Int) -> Token {
            return Token(type, startOffset, length)
    }

    // CreateToken - create or re-use a token object
    private func createToken(_ type: TokenType, _ data: Any) -> Token {
        return Token(type, data)
    }

    // FreeToken - return a token to the spare token pool
    private func freeToken(_ token: Token) {
        token.data = nil
        // Do nothing, we're notmaintaining a list of spare tokens
        // m_SpareTokens.Push(token)
    }
}

