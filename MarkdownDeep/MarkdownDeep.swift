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
import AppKit

open class ImageInfo {
    public var url: String!
    public var titled_image: Bool = false
    public var width: Int = 0
    public var height: Int = 0
}

class Markdown {
//    public var QualifyUrl: Func<String!,String!>!
//    public var GetImageSize: Func<ImageInfo!,Bool>!
//    public var PrepareLink: Func<HtmlTag!,Bool>!
//    public var PrepareImage: Func<HtmlTag!,Bool,Bool>!
//    public var FormatCodeBlock: Func<Markdown!,String!,String!>!

    internal var RenderingTitledImage: Bool = false

    var m_AbbreviationMap: [String: Abbreviation] = [:]
    var m_LinkDefinitions: CSDictionary<LinkDefinition> = CSDictionary<LinkDefinition>()
    var m_Footnotes: CSDictionary<Block> = CSDictionary<Block>()
    var m_UsedHeaderIDs: CSDictionary<Bool> = CSDictionary<Bool>()

    var m_SpareBlocks: Stack<Block> = Stack<Block>()
    var m_StringBuilder: String = ""
    var m_StringBuilderFinal: String = ""
    var m_StringScanner: StringScanner
    var m_SpanFormatter: SpanFormatter? = nil
    var m_UsedFootnotes: [Block]
    var m_AbbreviationList: [Abbreviation] = []

    private var summaryLength: Int = 0
    public var SummaryLength: Int
    {
        get { return summaryLength }
        set { summaryLength = newValue }
    }

    private var safeMode: Bool = false;
    public var SafeMode: Bool
    {
        get { return safeMode }
        set { safeMode = newValue }
    }

    private var extraMode: Bool = false
    public var ExtraMode: Bool
    {
        get { return extraMode }
        set { extraMode = newValue }
    }

    private var markdownInHtml: Bool = false
    public var MarkdownInHtml: Bool
    {
        get { return markdownInHtml }
        set { markdownInHtml = newValue }
    }

    private var autoHeadingIDs: Bool = false
    public var AutoHeadingIDs: Bool
    {
        get { return autoHeadingIDs }
        set { autoHeadingIDs = newValue }
    }

    private var urlBaseLocation: String! = nil
    public var UrlBaseLocation: String!
    {
        get { return urlBaseLocation }
        set { urlBaseLocation = newValue }
    }

    private var urlRootLocation: String! = nil
    public var UrlRootLocation: String!
    {
        get { return urlRootLocation }
        set { urlRootLocation = newValue }
    }

    private var newWindowForExternalLinks: Bool = false
    public var NewWindowForExternalLinks: Bool
    {
        get { return newWindowForExternalLinks }
        set { newWindowForExternalLinks = newValue }
    }

    private var newWindowForLocalLinks: Bool = false
    public var NewWindowForLocalLinks: Bool
    {
        get { return newWindowForLocalLinks }
        set { newWindowForLocalLinks = newValue }
    }

    private var documentRoot: String! = nil
    public var DocumentRoot: String!
    {
        get { return documentRoot }
        set { documentRoot = newValue }
    }

    private var documentLocation: String! = nil
    public var DocumentLocation: String!
    {
        get { return documentLocation }
        set { documentLocation = newValue }
    }

    private var maxImageWidth: Int = 0
    public var MaxImageWidth: Int
    {
        get { return maxImageWidth }
        set { maxImageWidth = newValue }
    }

    private var noFollowLinks: Bool = false
    public var NoFollowLinks: Bool
    {
        get { return noFollowLinks }
        set { noFollowLinks = newValue }
    }

    private var noFollowExternalLinks: Bool = false
    public var NoFollowExternalLinks: Bool
    {
        get { return noFollowExternalLinks }
        set { noFollowExternalLinks = newValue }
    }

    private var htmlClassFootnotes: String! = nil
    public var HtmlClassFootnotes: String!
    {
        get { return htmlClassFootnotes }
        set { htmlClassFootnotes = newValue }
    }

    private var extractHeadBlocks: Bool = false
    public var ExtractHeadBlocks: Bool
    {
        get { return extractHeadBlocks }
        set { extractHeadBlocks = newValue }
    }

    private var headBlockContent: String! = nil
    public var HeadBlockContent: String!
    {
        get { return headBlockContent }
        set { headBlockContent = newValue }
    }

    private var userBreaks: Bool = false
    public var UserBreaks: Bool
    {
        get { return userBreaks }
        set { userBreaks = newValue }
    }

    private var htmlClassTitledImages: String! = nil
    public var HtmlClassTitledImages: String!
    {
        get { return htmlClassTitledImages }
        set { htmlClassTitledImages = newValue }
    }

    private var sectionHeader: String! = nil
    public var SectionHeader: String!
    {
        get { return sectionHeader }
        set { sectionHeader = newValue }
    }

    private var sectionHeadingSuffix: String! = nil
    public var SectionHeadingSuffix: String!
    {
        get { return sectionHeadingSuffix }
        set { sectionHeadingSuffix = newValue }
    }

    private var sectionFooter: String! = nil
    public var SectionFooter: String!
    {
        get { return sectionFooter }
        set { sectionFooter = newValue }
    }

    internal var GetSpanFormatter: SpanFormatter!
    {
        get {
            if (m_SpanFormatter == nil) {
                m_SpanFormatter = SpanFormatter(self)
            }
            return m_SpanFormatter }
    }


    // Constructor
    public init() {
        htmlClassFootnotes = "footnotes"
        m_StringBuilder = ""
        m_StringBuilderFinal = ""
        m_StringScanner = StringScanner()
        m_LinkDefinitions.removeAll()
        m_Footnotes.removeAll()
        m_UsedFootnotes = []
        m_UsedHeaderIDs.removeAll()
        m_SpanFormatter = SpanFormatter(self)
    }

    internal func processBlocks(_ str: String) -> [Block] {
        //  Reset the list of link definitions
        m_LinkDefinitions.removeAll()
        m_Footnotes.removeAll()
        m_UsedFootnotes = []
        m_UsedHeaderIDs.removeAll()
        m_AbbreviationMap = [:]
        m_AbbreviationList = []

        //  Process blocks
        return BlockProcessor(self, MarkdownInHtml).process(str)
    }

    public func transform(_ str: String) -> String {
        var defs: CSDictionary<LinkDefinition> = CSDictionary<LinkDefinition>()
        return transform(str, &defs)
    }

    // Transform a string
    public func transform(_ str: String, _ definitions: inout CSDictionary<LinkDefinition>) -> String {
        //  Build blocks
        let blocks = processBlocks(str)

        //  Sort abbreviations by length, longest to shortest
        if m_AbbreviationMap.count > 0 {
            m_AbbreviationList = []
            for (_, itemValue) in m_AbbreviationMap {
                m_AbbreviationList.append(itemValue)
            }

            m_AbbreviationList.sort { (a, b) -> Bool in
                return (b.abbr.count - a.abbr.count) > 0
            }
        }
        //  Setup string builder
        var sb: String = m_StringBuilderFinal
        sb = ""
        if summaryLength != 0 {
            //  Render all blocks
            for i in 0 ... blocks.count - 1 {
                let b = blocks[i]
                b.renderPlain(self, &sb)
                if (SummaryLength > 0) && (sb.count > SummaryLength) {
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
                sb.append("\n<div class=\"")
                sb.append(HtmlClassFootnotes)
                sb.append("\">\n")
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
        }

        definitions = m_LinkDefinitions
        
        //  Done
        return sb
    }

    // Override to qualify non-local image and link urls
    open func onQualifyUrl(_ url: String!) -> String! {

        // TODO: User override function call... can I support this?
//        if QualifyUrl != nil {
//            var q = QualifyUrl(url)
//            if q != nil {
//                return url
//            }
//        }

        //  Quit if we don't have a base location
        if String.isNullOrEmpty(UrlBaseLocation) {
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
            if !String.isNullOrEmpty(UrlRootLocation) {
                return UrlRootLocation + url
            }
            //  Need to find domain root
            var pos: Int = UrlBaseLocation.indexOf(str: "://")
            if pos == -1 {
                pos = 0
            } else {
                pos = pos + 3
            }
            //  Find the first slash after the protocol separator
            pos = UrlBaseLocation.indexOf(str: "/", startPos: pos)

            //  Get the domain name
            let strDomain: String! = (pos < 0 ? UrlBaseLocation : UrlBaseLocation.substring(from: 0, for: pos))
            //  Join em
            return strDomain + url
        } else {
            if !UrlBaseLocation.hasSuffix("/") {
                return UrlBaseLocation + "/" + url
            } else {
                return UrlBaseLocation + url
            }
        }
    }

    // Override to supply the size of an image
    open func onGetImageSize(_ urlParam: String, _ TitledImage: Bool, _ width: inout Int, _ height: inout Int) -> Bool {
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
        var str: String! = (url.hasPrefix("/") ? DocumentRoot : DocumentLocation)
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

        if (MaxImageWidth != 0) && (width > MaxImageWidth) {
            let dHeight = Double(height)
            let dMaxImageWidth = Double(MaxImageWidth)
            let dWidth = Double(width)
            let dImgHeight = (dHeight * dMaxImageWidth) / dWidth
            height = Int(dImgHeight)
            //height = ((((height as? Double) * (MaxImageWidth as? Double)) / (width as? Double) as? Int)!)
            width = MaxImageWidth
        }
        return true
    }

    // Override to modify the attributes of a link
    open func onPrepareLink(_ tag: HtmlTag!) {

        // TODO: PrepareLink override method - can I support this?
//        if prepareLink != nil {
//            if prepareLink(tag) {
//                return
//            }
//        }

        let url: String! = tag.attribute(key: "href")
        //  No follow?

        if NoFollowLinks {
            tag.addAttribute(key: "rel", value: "nofollow")
        }
        //  No follow external links only
        if NoFollowExternalLinks {
            if Utils.isUrlFullyQualified(url) {
                tag.addAttribute(key: "rel", value: "nofollow")
            }
        }
        //  New window?
        if (NewWindowForExternalLinks
            && Utils.isUrlFullyQualified(url))
            || (NewWindowForLocalLinks
            && !Utils.isUrlFullyQualified(url)) {
            tag.addAttribute(key: "target", value: "_blank")
        }
        //  Qualify url
        tag.addAttribute(key: "href", value: onQualifyUrl(url))
    }

    // Override to modify the attributes of an image
    open func onPrepareImage(_ tag: HtmlTag!, _ TitledImage: Bool) {

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

    open func onSectionHeader(_ dest: inout String, _ Index: Int) {
        if sectionHeader != nil {
            dest.append(sectionHeader.replacingOccurrences(of: "{0}", with: String(Index)))
        }
    }

    open func onSectionHeadingSuffix(_ dest: inout String, _ Index: Int) {
        if sectionHeadingSuffix != nil {
            dest.append(sectionHeadingSuffix.replacingOccurrences(of: "{0}", with: String(Index)))
        }
    }

    open func onSectionFooter(_ dest: inout String, _ Index: Int) {
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
    public static func splitUserSections(_ markdown: String) -> [String] {
        //  Build blocks
        let md = MarkdownDeep.Markdown()
        md.UserBreaks = true

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
    public static func joinUserSections(_ sections: [String]) -> String {
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
    public static func splitSections(_ markdown: String!) -> [String] {
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
    public static func joinSections(_ sections: [String]) -> String {
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

    // Add a link definition
    internal func AddLinkDefinition(_ link: LinkDefinition!) {
        //  Store it
        m_LinkDefinitions[link.id] = link
    }

    internal func addFootnote(_ footnote: Block) {
        if let fnKey = footnote.data as? String {
            // add or update footnote depending on the key
            m_Footnotes[fnKey] = footnote
            return
        }
    }

    // Look up a footnote, claim it and return it's index (or -1 if not found)
    internal func claimFootnote(_ id: String) -> Int {

        if let fnDef = m_Footnotes[id] {
            m_UsedFootnotes.append(fnDef)
            m_Footnotes.remove(itemWithKey: id)

            return m_UsedFootnotes.count - 1
        }
        return -1
    }

    // Get a link definition
    public func getLinkDefinition(_ id: String!) -> LinkDefinition! {
        guard id != nil else { return nil }
        return m_LinkDefinitions[id]
    }

    internal func addAbbreviation(_ abbr: String, _ title: String) {
        if let mIndex = m_AbbreviationMap.index(forKey: abbr) {
            m_AbbreviationMap.remove(at: mIndex)
        }

        //  Store abbreviation
        m_AbbreviationMap[abbr] = Abbreviation(abbr: abbr, title: title)
    }

    internal func getAbbreviations() -> [Abbreviation] {
        return m_AbbreviationList
    }

    // HtmlEncode a range in a string to a specified string builder
    internal func htmlEncode(_ dest: inout String, _ str: String, _ start: Int, _ len: Int) {
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
        }}

    // HtmlEncode a string, also converting tabs to spaces (used by CodeBlocks)
    internal func htmlEncodeAndConvertTabsToSpaces(_ dest: inout String, _ str: String, _ start: Int, _ len: Int) {
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

    internal func makeUniqueHeaderID(_ strHeaderText: String) -> String {
        return makeUniqueHeaderID(strHeaderText, 0, strHeaderText.count)
    }

    internal func makeUniqueHeaderID(_ strHeaderText: String, _ startOffset: Int, _ length: Int) -> String! {
        if !AutoHeadingIDs {
            return nil
        }
        //  Extract a pandoc style cleaned header id from the header text
        var strBase: String! = GetSpanFormatter.makeID(strHeaderText, startOffset, length)
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
    internal func getStringBuilder() -> String {
        m_StringBuilder = ""
        return m_StringBuilder
    }
}

