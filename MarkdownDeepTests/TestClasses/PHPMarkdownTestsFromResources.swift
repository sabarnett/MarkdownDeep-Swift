// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest

class PHPMarkdownTestsFromResources: XCTestCase {

    func testEmailAutoLinksPhpMarkdown() {
        TestHelper().runTest(testFileName: "phpm-EmailAutoLinks", showDebugInfo: true)
    }

    func testBackslashEscapesPhpMarkdown() {
        TestHelper().runTest(testFileName: "phpm-BackslashEscapes")
    }

    func testCodeSpansPhpMarkdown() {
        TestHelper().runTest(testFileName: "phpm-CodeSpans")
    }

    func testCodeBlockInAListItemPhpMarkdown() {
        TestHelper().runTest(testFileName: "phpm-CodeBlockInAListItem")
    }

    func testEmphasisPhpMarkdown() {
        TestHelper().runTest(testFileName: "phpm-Emphasis")
    }

    func testHeadersPhpMarkdown() {
        TestHelper().runTest(testFileName: "phpm-Headers")
    }

    func testHorizontalRulesPhpMarkdown() {
        TestHelper().runTest(testFileName: "phpm-HorizontalRules")
    }

    func testInlineHTMLSimplePhpMarkdown() {
        TestHelper().runTest(testFileName: "phpm-InlineHTML(Simple)")
    }

    func testInlineHTMLSpanPhpMarkdown() {
        TestHelper().runTest(testFileName: "phpm-InlineHTML(Span)")
    }

    func testInlineHTMLcommentsPhpMarkdown() {
        TestHelper().runTest(testFileName: "phpm-InlineHTMLcomments")
    }

    func testInsDelPhpMarkdown() {
        TestHelper().runTest(testFileName: "phpm-InsDel")
    }

    func testLinksInlineStylePhpMarkdown() {
        TestHelper().runTest(testFileName: "phpm-LinksInlineStyle")
    }

    func testMD5HashesPhpMarkdown() {
        TestHelper().runTest(testFileName: "phpm-MD5Hashes")
    }

    func testNestingPhpMarkdown() {
        TestHelper().runTest(testFileName: "phpm-Nesting")
    }

    func testParensInURLPhpMarkdown() {
        TestHelper().runTest(testFileName: "phpm-ParensInURL")
    }

    func testSpecificBugsPpMarkdown() {
        TestHelper().runTest(testFileName: "phpm-SpecificBugs")
    }

    func testTightBlocksPhpMarkdown() {
        TestHelper().runTest(testFileName: "phpm-TightBlocks")
    }
}
