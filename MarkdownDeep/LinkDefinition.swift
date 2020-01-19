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

class LinkDefinition {

    private var linkId: String!
    private var linkUrl: String!
    private var linkTitle: String!

    // MARK:- Computed Properties

    var id: String! {
        get { return linkId }
        set { linkId = newValue }
    }

    var url: String! {
        get { return linkUrl }
        set { linkUrl = newValue }
    }

    var title: String! {
        get { return linkTitle }
        set { linkTitle = newValue }
    }

    // MARK:- Initialisers

    init(_ id: String!) {
        self.linkId = id
    }

    init(_ id: String!, _ url: String!) {
        self.linkId = id
        self.linkUrl = url
    }

    init(_ id: String!, _ url: String!, _ title: String!) {
        self.linkId = id
        self.linkUrl = url
        self.linkTitle = title
    }

    // MARK:- Rendering methods

    /// Render a link. This might be an anchor tag leading to a web page or a
    /// mailto link, leading to an email address.
    ///
    /// - Parameters:
    ///   - m: A reference to the master Makrdown object
    ///   - b: The buffer to append the output to
    ///   - link_text: The text for the link
    func renderLink(_ m: Markdown!, _ b: inout String, _ link_text: String!)
    {
        if url.lowercased().hasPrefix("mailto:") {
            b.append("<a href=\"")
            Utils.htmlRandomize(&b, url)
            b.append("\"")

            if title != nil && title.count > 0 {
                b.append(" title=\"")
                Utils.smartHtmlEncodeAmpsAndAngles(&b, title)
                b.append("\"")
            }
            b.append(">")
            Utils.htmlRandomize(&b, link_text)
            b.append("</a>")

        } else {
            let tag: HtmlTag = HtmlTag(name: "a")
            //  encode url
            var sb: String = ""
            Utils.smartHtmlEncodeAmpsAndAngles(&sb, url)
            tag.addAttribute(key: "href", value: sb)
            
            //  encode title
            if title != nil && title.count != 0 {
                sb = ""
                Utils.smartHtmlEncodeAmpsAndAngles(&sb, title)
                tag.addAttribute(key: "title", value: sb)
            }
            //  Do user processing
            m.onPrepareLink(tag)
            //  Render the opening tag
            tag.renderOpening(&b)
            b.append(link_text)
            //  Link text already escaped by SpanFormatter
            b.append("</a>")
        }
    }

    /// Render an image tag
    /// - Parameters:
    ///   - m: A reference to the master Markdown object
    ///   - b: The buffer to append the output to
    ///   - alt_text: Alt text for the image
    func renderImg(_ m: Markdown!, _ b: inout String, _ alt_text: String!) {
        let tag: HtmlTag = HtmlTag(name: "img")

        //  encode url
        var sb: String = ""
        Utils.smartHtmlEncodeAmpsAndAngles(&sb, url)
        tag.addAttribute(key: "src", value: sb)

        //  encode alt text
        if alt_text != nil && alt_text.count > 0 {
            sb = ""
            Utils.smartHtmlEncodeAmpsAndAngles(&sb, alt_text)
            tag.addAttribute(key: "alt", value: sb)
        }
        //  encode title
        if title != nil && title.count > 0 {
            sb = ""
            Utils.smartHtmlEncodeAmpsAndAngles(&sb, title)
            tag.addAttribute(key: "title", value: sb)
        }
        tag.closed = true
        m.onPrepareImage(tag, m.RenderingTitledImage)
        tag.renderOpening(&b)
    }

    // MARK:- Link scanner methods

    /// Parse a link definition from a string (used by test cases)
    /// - Parameters:
    ///   - str: The string to be scanned
    ///   - ExtraMode: Indicator of ExtraMode - which determines what characters are valid
    static func parseLinkDefinition(_ str: String, _ ExtraMode: Bool) -> LinkDefinition! {
        let p = StringScanner(str)
        return LinkDefinition.parseLinkDefinitionInternal(p, ExtraMode)
    }

    /// Parse a link definition from a string scanner instance
    /// - Parameters:
    ///   - p: The scting scanner containing the text to parse
    ///   - ExtraMode: ExtraMode indicator that influences what characters are valid
    static func parseLinkDefinition(_ p: StringScanner, _ ExtraMode: Bool) -> LinkDefinition! {
        let savepos: Int = p.position
        let l = parseLinkDefinitionInternal(p, ExtraMode)
        if l == nil {
            p.position = savepos
        }
        return l
    }

    //
    /// Parse just the link target.  For reference link definition, this is
    /// the bit after "[id]: thisbit". For inline link, this is the bit in
    /// the parens: [link text](thisbit)
    ///
    /// - Parameters:
    ///   - p: The string scanner containing the text to process
    ///   - id: An optional ID for the link
    ///   - ExtraMode: ExtraMode indicator
    static func parseLinkTarget(_ p: StringScanner, _ id: String!, _ ExtraMode: Bool) -> LinkDefinition! {

        p.skipWhitespace()
        if p.eol {
            return nil
        }

        //  Create the link definition
        let r = LinkDefinition(id)

        //  Is the url enclosed in angle brackets
        if p.skipChar("<") {
            //  Extract the url
            p.markPosition()

            //  Find end of the url
            while p.current != ">" {
                if p.eof {
                    return nil
                }
                p.skipEscapableChar(ExtraMode)
            }

            let url: String = p.extract()
            if !p.skipChar(">") {
                return nil
            }

            r.url = Utils.unescapeString(url.trimWhitespace(), ExtraMode)
            p.skipWhitespace()

        } else {

            //  Find end of the url
            p.markPosition()
            var paren_depth: Int = 1

            while !p.eol {
                let ch = p.current
                if (ch.isWhitespace) {
                    break
                }
                if id == nil {
                    if ch == "(" {
                        paren_depth += 1
                    } else if ch == ")" {
                        paren_depth -= 1
                        if paren_depth == 0 {
                            break
                        }
                    }
                }

                p.skipEscapableChar(ExtraMode)
            }
            r.url = Utils.unescapeString(p.extract()!.trimWhitespace(), ExtraMode)
        }

        p.skipLinespace()
        //  End of inline target
        if p.doesMatch(")") {
            return r
        }

        let bOnNewLine: Bool = p.eol
        let posLineEnd: Int = p.position
        if p.eol {
            p.skipEol()
            p.skipLinespace()
        }

        //  Work out what the title is delimited with
        var delim: Character
        switch p.current {
            case "\'", "\"":
                delim = p.current
            case "(":
                delim = ")"
            default:
                if bOnNewLine {
                    p.position = posLineEnd
                    return r
                } else {
                    return nil
                }
        }
        //  Skip the opening title delimiter
        p.skipForward(1)
        //  Find the end of the title
        p.markPosition()

        while true {
            if p.eol {
                return nil
            }
            if p.current == delim {
                if delim != ")" {
                    let savepos: Int = p.position
                    //  Check for embedded quotes in title
                    //  Skip the quote and any trailing whitespace
                    p.skipForward(1)
                    p.skipLinespace()
                    //  Next we expect either the end of the line for a link definition
                    //  or the close bracket for an inline link
                    if ((id == nil) && (p.current != ")")) || (id != nil && !p.eol) {
                        continue
                    }
                    p.position = savepos
                }
                //  End of title
                break
            }

            p.skipEscapableChar(ExtraMode)
        }

        //  Store the title
        r.title = Utils.unescapeString(p.extract(), ExtraMode)
        //  Skip closing quote
        p.skipForward(1)
        //  Done!
        return r
    }

    private static func parseLinkDefinitionInternal(_ p: StringScanner, _ ExtraMode: Bool) -> LinkDefinition! {
        //  Skip leading white space
        p.skipWhitespace()

        //  Must start with an opening square bracket
        if !p.skipChar("[") {
            return nil
        }
        //  Extract the id
        p.markPosition()

        if !p.find("]") {
            return nil
        }
        let id = p.extract()
        if id == nil || id!.count == 0 {
            return nil
        }

        if !p.skipString("]:") {
            return nil
        }
        //  Parse the url and title
        let link = parseLinkTarget(p, id, ExtraMode)
        //  and trailing whitespace
        p.skipLinespace()
        //  Trailing crap, not a valid link reference...
        if !p.eol {
            return nil
        }
        return link
    }

}
