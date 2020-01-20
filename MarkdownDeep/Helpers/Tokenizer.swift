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

struct Tokenizer {
    private var m: Markdown
    private var p: SpanFormatter

    init(m: Markdown, p: SpanFormatter) {
        self.m = m
        self.p = p
    }

    // Scan the input string, creating tokens for anything special
    func tokenize(_ str: String, _ start: Int, _ len: Int) {
        //  Prepare
        p.reset(str, start, len)

        p.m_Tokens.removeAll()
        var emphasis_marks: [Token] = []
        let Abbreviations: [Abbreviation] = m.getAbbreviations()
        let ExtraMode: Bool = m.extraMode

        //  Scan string
        var start_text_token: Int = p.position
        while !p.eof {
            let end_text_token: Int = p.position

            //  Work out token
            var token: Token! = nil
            switch p.current {
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
                    let linkpos: Int = p.position
                    token = processLinkOrImageOrFootnote()

                    //  Rewind if invalid syntax
                    //  (the '[' or '!' will be treated as a regular character and processed below)
                    if token == nil {
                        p.position = linkpos
                    }

                case "<":
                    //  Is it a valid html tag?
                    let save: Int = p.position
                    let tag: HtmlTag! = HtmlTag.parse(scanner: p)
                    if tag != nil {
                        if !m.safeMode || tag.isSafe() {
                            //  Yes, create a token for it
                            token = Token(TokenType.HtmlTag, save, p.position - save)
                        } else {
                            //  No, rewrite and encode it
                            p.position = save
                        }
                    } else {
                        //  No, rewind and check if it's a valid autolink eg: <google.com>
                        p.position = save
                        token = processAutoLink()
                        if token == nil {
                            p.position = save
                        }
                    }

            case "&":
                //  Is it a valid html entity
                let save: Int = p.position
                var unused: String! = nil
                if p.skipHtmlEntity(&unused) {
                    //  Yes, create a token for it
                    token = Token(TokenType.Html, save, p.position - save)
                }

            case " ":
                    //  Check for double space at end of a line
                if (p.charAtOffset(1) == " ") && p.isLineEnd(p.charAtOffset(2)) {
                        //  Yes, skip it
                    p.skipForward(2)
                        //  Don't put br's at the end of a paragraph
                    if !p.eof {
                        p.skipEol()
                            token = Token(TokenType.br, end_text_token, 0)
                        }
                    }
                case "\\":
                    //  Check followed by an escapable character
                    if Utils.isEscapableChar(p.charAtOffset(1), ExtraMode) {
                        token = Token(TokenType.Text, p.position + 1, 1)
                        p.skipForward(2)
                    }
            default:
                break
            }

            //  Look for abbreviations.

            // SAB Never finds abbreviations! Is skipString working???
            let ch = p.charAtOffset(-1)
            if (token == nil) && Abbreviations.count > 0 &&
                !(ch.isLetter || ch.isNumber) {
                let savepos = p.position
                for abbr in Abbreviations {
                    if p.skipString(abbr.abbr) {
                        let chr = p.current
                        if !(chr.isLetter || chr.isNumber) {
                            token = Token(TokenType.abbreviation, abbr)
                            break
                        }

                    }
                    p.position = savepos
                }
            }

            //  If token found, append any preceeding text and the new token to the token list
            if token != nil {
                //  Create a token for everything up to the special character
                if end_text_token > start_text_token {
                    p.m_Tokens.append(
                        Token(TokenType.Text, start_text_token, end_text_token - start_text_token))
                }

                //  Add the new token
                p.m_Tokens.append(token)
                //  Remember where the next text token starts
                start_text_token = p.position
            } else {
                //  Skip a single character and keep looking
                p.skipForward(1)
            }
        }

        //  Append a token for any trailing text after the last token.
        if p.position > start_text_token {
            p.m_Tokens.append(Token(TokenType.Text, start_text_token, p.position - start_text_token))
        }
        //  Do we need to resolve and emphasis marks?
        if emphasis_marks.count > 0 {
            resolveEmphasisMarks(&p.m_Tokens, &emphasis_marks)
        }
        //  Done!
        return
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
        let ch = p.current
        //let altch = (ch == "*" ? "_" : "*")
        let savepos: Int = p.position

        //  Check for a consecutive sequence of just '_' and '*'

        if p.bof || p.charAtOffset(-1).isWhitespace {
            while isEmphasisChar(p.current) {
                p.skipForward(1)
            }

            if p.eof || p.current.isWhitespace {
                return Token(TokenType.Html, savepos, p.position - savepos)
            }
            //  Rewind
            p.position = savepos
        }

        //  Scan backwards and see if we have space before
        while isEmphasisChar(p.charAtOffset(-1)) {
            p.skipForward(-1)
        }

        let bSpaceBefore: Bool = p.bof || p.charAtOffset(-1).isWhitespace
        p.position = savepos

        //  Count how many matching emphasis characters
        while p.current == ch {
            p.skipForward(1)
        }

        let count: Int = p.position - savepos
        //  Scan forwards and see if we have space after
        while isEmphasisChar(p.charAtOffset(1)) {
            p.skipForward(1)
        }

        let bSpaceAfter: Bool = p.eof || p.current.isWhitespace
        p.position = savepos + count

        if bSpaceBefore {
            return Token(TokenType.opening_mark, savepos, p.position - savepos)
        }

        if bSpaceAfter {
            return Token(TokenType.closing_mark, savepos, p.position - savepos)
        }

        if m.extraMode
            && (ch == "_")
            && (p.current.isLetter || p.current.isNumber) {
            return nil
        }

        return Token(TokenType.internal_mark, savepos, p.position - savepos)
    }

    // Process a ``` code span ```
    private func processCodeSpan() -> Token! {
        let start: Int = p.position
        //  Count leading ticks
        var tickcount: Int = 0
        while p.skipChar("`") {
            tickcount += 1
        }

        //  Skip optional leading space...
        p.skipWhitespace()

        //  End?
        if p.eof {
            return Token(TokenType.Text, start, p.position - start)
        }

        let startofcode: Int = p.position

        //  Find closing ticks
        if !p.find(p.substring(start, tickcount)) {
            return Token(TokenType.Text, start, p.position - start)
        }

        //  Save end position before backing up over trailing whitespace
        let endpos: Int = p.position + tickcount
        while p.charAtOffset(-1).isWhitespace {
            p.skipForward(-1)
        }

        //  Create the token, move back to the end and we're done
        let ret = Token(TokenType.code_span, startofcode, p.position - startofcode)
        p.position = endpos
        return ret
    }


    // Process [link] and ![image] directives
    private func processLinkOrImageOrFootnote() -> Token! {
        //  Link or image?
        let token_type: TokenType = (p.skipChar("!") ? TokenType.img : TokenType.link)
        //  Opening '['
        if !p.skipChar("[") {
            return nil
        }
        //  Is it a foonote?
        var savepos = p.position
        if m.extraMode && token_type == TokenType.link && p.skipChar("^") {
            p.skipLinespace()

            //  Parse it
            var id: String!
            if p.skipFootnoteID(&(id)) && p.skipChar("]") {
                //  Look it up and create footnote reference token
                let footnote_index: Int = m.claimFootnote(id)
                if footnote_index >= 0 {
                    //  Yes it's a footnote
                    return Token(TokenType.footnote, FootnoteReference(index: footnote_index, id: id))
                }
            }
            //  Rewind
            p.position = savepos
        }

        if p.disableLinks && token_type == TokenType.link {
            return nil
        }

        let ExtraMode: Bool = m.extraMode
        //  Find the closing square bracket, allowing for nesting, watching for
        //  escapable characters
        p.markPosition()
        var depth: Int = 1
        while !p.eof {
            let ch: Character = p.current
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
            p.skipEscapableChar(ExtraMode)
        }

        //  Quit if end
        if p.eof {
            return nil
        }

        //  Get the link text and unescape it
        let link_text: String! = Utils.unescapeString(p.extract(), ExtraMode)

        //  The closing ']'
        p.skipForward(1)

        //  Save position in case we need to rewind
        savepos = p.position

        //  Inline links must follow immediately
        if p.skipChar("(") {
            //  Extract the url and title
            let link_def = LinkDefinition.parseLinkTarget(p, nil, m.extraMode)
            if link_def == nil {
                return nil
            }
            //  Closing ')'
            p.skipWhitespace()
            if !p.skipChar(")") {
                return nil
            }
            //  Create the token
            return Token(token_type, LinkInfo(linkDef: link_def!, linkText: link_text))
        }

        //  Optional space or tab
        if !p.skipChar(" ") {
            p.skipChar("\t")
        }
        //  If there's line end, we're allow it and as must line space as we want
        //  before the link id.
        if p.eol {
            p.skipEol()
            p.skipLinespace()
        }

        //  Reference link?
        var link_id: String! = nil
        if p.current == "[" {
            //  Skip the opening '['
            p.skipForward(1)
            //  Find the start/end of the id
            p.markPosition()
            if !p.find("]") {
                return nil
            }
            //  Extract the id
            link_id = p.extract()
            //  Skip closing ']'
            p.skipForward(1)
        } else {
            //  Rewind to just after the closing ']'
            p.position = savepos
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
        let def = m.getLinkDefinition(link_id)
        if def == nil {
            return nil
        }
        //  Create a token
        return Token(token_type, LinkInfo(linkDef: def!, linkText: link_text))
    }

    //  Process auto links eg: <google.com>
    private func processAutoLink() -> Token! {
        if p.disableLinks {
            return nil
        }
        //  Skip the angle bracket and remember the start
        p.skipForward(1)
        p.markPosition()

        let ExtraMode: Bool = m.extraMode
        //  Allow anything up to the closing angle, watch for escapable characters
        while !p.eof {
            let ch: Character = p.current
            //  No whitespace allowed
            if ch.isWhitespace {
                break
            }
            //  End found?
            if ch == ">" {
                var url: String! = Utils.unescapeString(p.extract(), ExtraMode)
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
                    p.skipForward(1)
                    return Token(TokenType.link, li!)
                }
                return nil
            }
            p.skipEscapableChar(ExtraMode)
        }//  Didn't work
        return nil
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
                    if p.input.charAt(at: opening_mark.startOffset) !=
                        p.input.charAt(at: closing_mark.startOffset) {
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
                if p.input.charAt(at: opening_mark.startOffset) != p.input.charAt(at: closing_mark.startOffset) {
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
                if p.input.charAt(at: opening_mark.startOffset) != p.input.charAt(at: closing_mark.startOffset) {
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

    private func isEmphasisChar(_ ch: Character) -> Bool {
        return (ch == "_") || (ch == "*")
    }


    // Split mark token
    @discardableResult
    private func splitMarkToken(_ tokens: inout [Token], _ marks: inout [Token], _ token: Token, _ position: Int) -> Token! {

        //  Create the new rhs token
        let tokenRhs: Token! = Token(token.type, token.startOffset + position, token.length - position)

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
}
