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
import AppKit

public class Markdown {
//    public var QualifyUrl: Func<String!,String!>!
//    public var GetImageSize: Func<ImageInfo!,Bool>!
//    public var PrepareLink: Func<HtmlTag!,Bool>!
//    public var PrepareImage: Func<HtmlTag!,Bool,Bool>!
//    public var FormatCodeBlock: Func<Markdown!,String!,String!>!

    var renderingTitledImage: Bool = false

    var m_AbbreviationMap = CSDictionary<Abbreviation>()
    var m_LinkDefinitions = CSDictionary<LinkDefinition>()
    var m_Footnotes = CSDictionary<Block>()
    var m_UsedHeaderIDs = CSDictionary<Bool>()

    var m_StringBuilder: String = ""
    var m_StringScanner: StringScanner
    var m_SpanFormatter: SpanFormatter? = nil
    var m_UsedFootnotes: [Block] = []
    var m_AbbreviationList: [Abbreviation] = []

    // MARK:- Computed properies and user settable options

    public var summaryLength: Int = 0
    public var safeMode: Bool = false;
    public var extraMode: Bool = false
    public var markdownInHtml: Bool = false
    public var autoHeadingIDs: Bool = false
    public var urlBaseLocation: String! = nil
    public var urlRootLocation: String! = nil
    public var newWindowForExternalLinks: Bool = false
    public var newWindowForLocalLinks: Bool = false
    public var documentRoot: String! = nil
    public var documentLocation: String! = nil
    public var maxImageWidth: Int = 0
    public var noFollowLinks: Bool = false
    public var noFollowExternalLinks: Bool = false
    public var htmlClassFootnotes: String! = nil
    public var extractHeadBlocks: Bool = false
    public var headBlockContent: String! = nil
    public var userBreaks: Bool = false
    public var htmlClassTitledImages: String! = nil
    public var sectionHeader: String! = nil
    public var sectionHeadingSuffix: String! = nil
    public var sectionFooter: String! = nil

    var getSpanFormatter: SpanFormatter!
    {
        get {
            if (m_SpanFormatter == nil) {
                m_SpanFormatter = SpanFormatter(self)
            }
            return m_SpanFormatter }
    }

    // MARK:- Initialisers

    public init() {
        htmlClassFootnotes = "footnotes"
        m_StringBuilder = ""
        m_StringScanner = StringScanner()
        m_LinkDefinitions.removeAll()
        m_Footnotes.removeAll()
        m_UsedFootnotes.removeAll()
        m_UsedHeaderIDs.removeAll()
        m_SpanFormatter = SpanFormatter(self)
    }

    // MARK:- Public interface

    /// Transform a string, returning the transformed string and a list of links
    /// contained in the output.
    /// - Parameter str: The string to be parsed
    public func transform(_ str: String) -> String {

        let blocks = processBlocks(str)

        createAbbreviationList()

        // This is the string where the results will be stored.
        var sb: String = ""
        if summaryLength != 0 {
            //  Render all blocks
            for i in 0 ... blocks.count - 1 {
                let b = blocks[i]
                b.renderPlain(self, &sb)
                if (summaryLength > 0) && (sb.count > summaryLength) {
                    break
                }
            }
        } else {
            var iSection: Int = -1
            //  Leading section (ie: plain text before first heading)
            if (blocks.count > 0) && !isSectionHeader(blocks[0]) {
                iSection = 0
                onSectionHeader(&sb, 0)
                onSectionHeadingSuffix(&sb, 0)
            }
            //  Render all blocks
            for i in 0 ... blocks.count - 1 {
                let b = blocks[i]
                //  New section?
                if isSectionHeader(b) {
                    //  Finish the previous section
                    if iSection >= 0 {
                        onSectionFooter(&sb, iSection)
                    }
                    //  Work out next section index
                    iSection = (iSection < 0 ? 1 : iSection + 1)
                    //  Section header
                    onSectionHeader(&sb, iSection)
                    //  Section Heading
                    b.render(self, &sb)
                    //  Section Heading suffix
                    onSectionHeadingSuffix(&sb, iSection)
                } else {
                    //  Regular section
                    b.render(self, &sb)
                }
            }
            //  Finish final section
            if blocks.count > 0 {
                onSectionFooter(&sb, iSection)
            }
            //  Render footnotes
            if m_UsedFootnotes.count > 0 {
                renderFootnotes(&sb)
            }
        }

        return sb
    }


    // MARK:- Helper functions

    private func processBlocks(_ str: String) -> [Block] {
        //  Reset the list of link definitions
        m_LinkDefinitions.removeAll()
        m_Footnotes.removeAll()
        m_UsedFootnotes.removeAll()
        m_UsedHeaderIDs.removeAll()
        m_AbbreviationMap.removeAll()
        m_AbbreviationList.removeAll()

        return BlockProcessor(self, markdownInHtml).process(str)
    }

    /// Copy the items from the abbreviation map to the abbreviation list
    /// and sort the list.
    fileprivate func createAbbreviationList() {
        m_AbbreviationList.removeAll()

        if m_AbbreviationMap.count > 0 {
            for (_, itemValue) in m_AbbreviationMap {
                m_AbbreviationList.append(itemValue)
            }

            m_AbbreviationList.sort { (a, b) -> Bool in
                return (b.abbr.count - a.abbr.count) > 0
            }
        }
    }

    fileprivate func renderFootnotes(_ sb: inout String) {
        sb.append("\n<div class=\"\(htmlClassFootnotes!)\">\n")
        sb.append("<hr />\n")
        sb.append("<ol>\n")

        for i in 0 ... m_UsedFootnotes.count - 1 {
            let fn = m_UsedFootnotes[i]
            let fnData = (fn.data as? String) ?? ""
            sb.append("<li id=\"fn:")
            sb.append(fnData)
            //  footnote id
            sb.append("\">\n")
            //  We need to get the return link appended to the last paragraph
            //  in the footnote
            let strReturnLink: String = "<a href=\"#fnref:" + fnData + "\" rev=\"footnote\">&#8617;</a>"

            //  Get the last child of the footnote
            var child = fn.children[fn.children.count - 1]
            if child.blockType == BlockType.p {
                child.blockType = BlockType.p_footnote
                child.data = strReturnLink
            } else {
                child = Block()
                child.contentLen = 0
                child.blockType = BlockType.p_footnote
                child.data = strReturnLink
                fn.children.append(child)
            }
            fn.render(self, &sb)
            sb.append("</li>\n")
        }

        sb.append("</ol>\n")
        sb.append("</div>\n")
    }

    // Override to qualify non-local image and link urls
    func onQualifyUrl(_ url: String!) -> String {

        // TODO: User override function call... can I support this?
//        if QualifyUrl != nil {
//            var q = QualifyUrl(url)
//            if q != nil {
//                return url
//            }
//        }

        //  Quit if we don't have a base location
        if String.isNullOrEmpty(urlBaseLocation) {
            return url
        }
        //  Is the url a fragment?
        if url.hasPrefix("#") {
            return url
        }
        //  Is the url already fully qualified?
        if Utils.isUrlFullyQualified(url) {
            return url
        }
        if url.hasPrefix("/") {
            if !String.isNullOrEmpty(urlRootLocation) {
                return urlRootLocation + url
            }
            //  Need to find domain root
            var pos: Int = urlBaseLocation.indexOf(str: "://")
            if pos == -1 {
                pos = 0
            } else {
                pos = pos + 3
            }
            //  Find the first slash after the protocol separator
            pos = urlBaseLocation.indexOf(str: "/", startPos: pos)

            //  Get the domain name
            let strDomain: String! = (pos < 0 ? urlBaseLocation : urlBaseLocation.substring(from: 0, for: pos))
            //  Join em
            return strDomain + url
        } else {
            if !urlBaseLocation.hasSuffix("/") {
                return urlBaseLocation + "/" + url
            } else {
                return urlBaseLocation + url
            }
        }
    }

    // Override to supply the size of an image
    func onGetImageSize(_ urlParam: String, _ TitledImage: Bool, _ width: inout Int, _ height: inout Int) -> Bool {
        var url = urlParam;

        // TODO: Override for get image size. Can I support this?
//        if GetImageSize != nil {
//            var info = ImageInfo(url: url, titled_image: TitledImage)
//            if getImageSize(info) {
//                width = info.width
//                height = info.height
//                return true
//            }
//        }

        width = 0
        height = 0

        if Utils.isUrlFullyQualified(url) {
            return false
        }
        //  Work out base location
        var str: String! = (url.hasPrefix("/") ? documentRoot : documentLocation)
        if String.isNullOrEmpty(str) {
            return false
        }
        //  Work out file location
        if str.hasSuffix("/") || str.hasSuffix("\\") {
            str = str.substring(from: 0, for: str.count - 1)
        }
        if url.hasPrefix("/") {
            url = url.right(from: 1)
        }
        str = str + "\\" + url.replacingOccurrences(of: "/", with: "\\")

        //
        // Create an image object from the uploaded file
        guard let fileUrl = URL(string: str) else { return false }
        guard let imgFile = NSImage(contentsOf: fileUrl) else { return false }

        //var img = System.Drawing.Image.FromFile(str)
        width = Int(imgFile.size.width)
        height = Int(imgFile.size.height)

        if (maxImageWidth != 0) && (width > maxImageWidth) {
            let dHeight = Double(height)
            let dMaxImageWidth = Double(maxImageWidth)
            let dWidth = Double(width)
            let dImgHeight = (dHeight * dMaxImageWidth) / dWidth
            height = Int(dImgHeight)
            //height = ((((height as? Double) * (MaxImageWidth as? Double)) / (width as? Double) as? Int)!)
            width = maxImageWidth
        }
        return true
    }

    // Override to modify the attributes of a link
    func onPrepareLink(_ tag: HtmlTag) {

        // TODO: PrepareLink override method - can I support this?
//        if prepareLink != nil {
//            if prepareLink(tag) {
//                return
//            }
//        }

        let url: String! = tag.attribute(key: "href")

        //  No follow?
        if noFollowLinks {
            tag.addAttribute(key: "rel", value: "nofollow")
        }

        //  No follow external links only
        if noFollowExternalLinks {
            if Utils.isUrlFullyQualified(url) {
                tag.addAttribute(key: "rel", value: "nofollow")
            }
        }

        //  New window?
        if (newWindowForExternalLinks
            && Utils.isUrlFullyQualified(url))
            || (newWindowForLocalLinks
            && !Utils.isUrlFullyQualified(url)) {
            tag.addAttribute(key: "target", value: "_blank")
        }

        //  Qualify url
        tag.addAttribute(key: "href", value: onQualifyUrl(url))
    }

    // Override to modify the attributes of an image
    func onPrepareImage(_ tag: HtmlTag!, _ TitledImage: Bool) {

        // TODO: PrepareImage override - can I support this?
//        if PrepareImage != nil {
//            if PrepareImage(tag, TitledImage) {
//                return
//            }
//        }

        var width: Int = 0
        var height: Int = 0
        if onGetImageSize(tag.attribute(key: "src")!, TitledImage, &(width), &(height)) {
            tag.addAttribute(key: "width", value: String(width))
            tag.addAttribute(key: "height", value: String(height))
        }
        //  Now qualify the url
        tag.addAttribute(key: "src", value: onQualifyUrl(tag.attribute(key: "src")))
    }

    func onSectionHeader(_ dest: inout String, _ Index: Int) {
        if sectionHeader != nil {
            dest.append(sectionHeader.replacingOccurrences(of: "{0}", with: String(Index)))
        }
    }

    func onSectionHeadingSuffix(_ dest: inout String, _ Index: Int) {
        if sectionHeadingSuffix != nil {
            dest.append(sectionHeadingSuffix.replacingOccurrences(of: "{0}", with: String(Index)))
        }
    }

    func onSectionFooter(_ dest: inout String, _ Index: Int) {
        if sectionFooter != nil {
            dest.append(sectionFooter.replacingOccurrences(of: "{0}", with: String(Index)))
        }
    }

    func isSectionHeader(_ b: Block) -> Bool {
        return (b.blockType == BlockType.h1)
            || (b.blockType == BlockType.h2)
            || (b.blockType == BlockType.h3)
    }

    // Split the markdown into sections, one section for each
    //  top level heading
    static func splitUserSections(_ markdown: String) -> [String] {
        //  Build blocks
        let md = MarkdownDeep.Markdown()
        md.userBreaks = true

        //  Process blocks
        let blocks = md.processBlocks(markdown)

        //  Create sections
        var Sections: [String] = []
        var iPrevSectionOffset: Int = 0
        for i in 0 ... blocks.count - 1 {
            let b = blocks[i]
            if b.blockType == BlockType.user_break {
                //  Get the offset of the section
                let iSectionOffset: Int = b.lineStart
                //  Add section
                Sections.append(markdown.substring(from: iPrevSectionOffset, for: iSectionOffset - iPrevSectionOffset).trimWhitespace())
                //  Next section starts on next line
                if (i + 1) < blocks.count {
                    iPrevSectionOffset = blocks[i + 1].lineStart
                    if iPrevSectionOffset == 0 {
                        iPrevSectionOffset = blocks[i + 1].contentStart
                    }
                } else {
                    iPrevSectionOffset = markdown.count
                }
            }
        }
        //  Add the last section
        if markdown.count > iPrevSectionOffset {
            Sections.append(markdown.right(from: iPrevSectionOffset).trimWhitespace())
        }
        return Sections
    }

    // Join previously split sections back into one document
    static func joinUserSections(_ sections: [String]) -> String {
        var sb = ""
        for i in 0 ... sections.count - 1 {
            if i > 0 {
                //  For subsequent sections, need to make sure we
                //  have a line break after the previous section.
                let strPrev: String = sections[sections.count - 1]
                if (strPrev.count > 0)
                    && !strPrev.hasSuffix("\n")
                    && !strPrev.hasSuffix("\r") {
                    sb.append("\n")
                }
                sb.append("\n===\n\n")
            }
            sb.append(sections[i])
        }
        return sb
    }

    // Split the markdown into sections, one section for each
    //  top level heading
    static func splitSections(_ markdown: String!) -> [String] {
        //  Build blocks
        let md = MarkdownDeep.Markdown()
        //  Process blocks
        let blocks = md.processBlocks(markdown)
        //  Create sections
        var Sections: [String] = []
        var iPrevSectionOffset: Int = 0
        for i in 0 ... blocks.count - 1 {
            let b = blocks[i]
            if md.isSectionHeader(b) {
                //  Get the offset of the section
                let iSectionOffset: Int = b.lineStart
                //  Add section
                Sections.append(markdown.substring(from: iPrevSectionOffset, for: iSectionOffset - iPrevSectionOffset))
                iPrevSectionOffset = iSectionOffset
            }
        }
        //  Add the last section
        if markdown.count > iPrevSectionOffset {
            Sections.append(markdown.right(from: iPrevSectionOffset))
        }
        return Sections
    }

    // Join previously split sections back into one document
    static func joinSections(_ sections: [String]) -> String {
        var sb = ""
        for i in 0 ... sections.count - 1 {
            if i > 0 {
                //  For subsequent sections, need to make sure we
                //  have a line break after the previous section.
                let strPrev: String! = sections[sections.count - 1]
                if (strPrev.count > 0)
                    && !strPrev.hasSuffix("\n")
                    && !strPrev.hasSuffix("\r") {
                    sb.append("\n")
                }
            }
            sb.append(sections[i])
        }
        return sb
    }

    func addFootnote(_ footnote: Block) {
        if let fnKey = footnote.data as? String {
            // add or update footnote depending on the key
            m_Footnotes[fnKey] = footnote
            return
        }
    }

    // Look up a footnote, claim it and return it's index (or -1 if not found)
    func claimFootnote(_ id: String) -> Int {

        if let fnDef = m_Footnotes[id] {
            m_UsedFootnotes.append(fnDef)
            m_Footnotes.remove(itemWithKey: id)

            return m_UsedFootnotes.count - 1
        }
        return -1
    }

    // Add a link definition
    func addLinkDefinition(_ link: LinkDefinition!) {
        //  Store it
        m_LinkDefinitions[link.id] = link
    }

    // Get a link definition
    func getLinkDefinition(_ id: String!) -> LinkDefinition! {
        guard id != nil else { return nil }
        return m_LinkDefinitions[id]
    }

    func addAbbreviation(_ abbr: String, _ title: String) {
        m_AbbreviationMap[abbr] = Abbreviation(abbr: abbr, title: title)
    }

    func getAbbreviations() -> [Abbreviation] {
        return m_AbbreviationList
    }

    // HtmlEncode a range in a string to a specified string builder
    func htmlEncode(_ dest: inout String, _ str: String, _ start: Int, _ len: Int) {
        m_StringScanner.reset(str, start, len)
        let p = m_StringScanner
        while !p.eof {
            let ch = p.current
            switch ch {
                case "&":
                    dest.append("&amp;")
                case "<":
                    dest.append("&lt;")
                case ">":
                    dest.append("&gt;")
                case "\"":
                    dest.append("&quot;")
                default:
                    dest.append(ch)
            }
            p.skipForward(1)
        }
    }

    // HtmlEncode a string, also converting tabs to spaces (used by CodeBlocks)
    func htmlEncodeAndConvertTabsToSpaces(_ dest: inout String, _ str: String, _ start: Int, _ len: Int) {
        m_StringScanner.reset(str, start, len)
        let p = m_StringScanner
        var pos: Int = 0
        while !p.eof {
            let ch = p.current
            switch ch {
                case "\t":
                    dest.append(" ")
                    pos += 1
                    while (pos % 4) != 0 {
                        dest.append(" ")
                        pos += 1
                    }
                    pos -= 1
                case "\r", "\n":
                    dest.append("\n")
                    pos = 0
                    p.skipEol()
                    continue
                case "&":
                    dest.append("&amp;")
                case "<":
                    dest.append("&lt;")
                case ">":
                    dest.append("&gt;")
                case "\"":
                    dest.append("&quot;")
                default:
                    dest.append(ch)
            }
            p.skipForward(1)
            pos += 1
        }}

    func makeUniqueHeaderID(_ strHeaderText: String) -> String {
        return makeUniqueHeaderID(strHeaderText, 0, strHeaderText.count)
    }

    func makeUniqueHeaderID(_ strHeaderText: String, _ startOffset: Int, _ length: Int) -> String! {
        if !autoHeadingIDs {
            return nil
        }
        //  Extract a pandoc style cleaned header id from the header text
        var strBase: String! = getSpanFormatter.makeID(strHeaderText, startOffset, length)
        //  If nothing left, use "section"
        if strBase == nil || strBase!.count == 0
        {
            strBase = "section"
        }

        //  Make sure it's unique by append -n counter
        var strWithSuffix: String! = strBase
        var counter: Int = 1

        while m_UsedHeaderIDs[strWithSuffix] != nil {
            strWithSuffix = strBase + "-" + String(counter)
            counter += 1
        }

        //  Store it
        m_UsedHeaderIDs[strWithSuffix] = true

        //  Return it
        return strWithSuffix
    }

    // * Get this markdown processors string builder.
    //          *
    //          * We re-use the same string builder whenever we can for performance.
    //          * We just reset the length before starting to / use it again, which
    //          * hopefully should keep the memory around for next time.
    //          *
    //          * Note, care should be taken when using this string builder to not
    //          * call out to another function that also uses it.
    func getStringBuilder() -> String {
        m_StringBuilder = ""
        return m_StringBuilder
    }
}

