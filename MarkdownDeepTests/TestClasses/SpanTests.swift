// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest

class SpanTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testBackslashEscapes() {
        TestHelper().runTest(testFileName: "BackslashEscapes")
    }

    func testEmphasis() {
        TestHelper().runTest(testFileName: "Emphasis")
    }

    func testEscapesInUrls() {
        TestHelper().runTest(testFileName: "EscapesInUrls", showDebugInfo: true)
    }

    func testExplicitReferenceLinkWithoutTitle() {
        TestHelper().runTest(testFileName: "ExplicitReferenceLinkWithoutTitle",
        showDebugInfo: true)
    }

    func testExplicitReferenceLinkWithTitle() {
        TestHelper().runTest(testFileName: "ExplicitReferenceLinkWithTitle", showDebugInfo: true)
    }

    func testFormattingInLinkText() {
        TestHelper().runTest(testFileName: "FormattingInLinkText")
    }

    func testHtmlEncodeLinks() {
        TestHelper().runTest(testFileName: "HtmlEncodeLinks", showDebugInfo: true)
    }

    func testImplicitReferenceLinkWithoutTitle() {
        TestHelper().runTest(testFileName: "ImplicitReferenceLinkWithoutTitle")
    }

    func testImplicitReferenceLinkWithTitle() {
        TestHelper().runTest(testFileName: "ImplicitReferenceLinkWithTitle")
    }

    func testInlineLinkWithTitle() {
        TestHelper().runTest(testFileName: "InlineLinkWithTitle")
    }

    func testLinkedImage() {
        TestHelper().runTest(testFileName: "LinkedImage")
    }

    func testLinkTitlesWithEmbeddedQuotes() {
        TestHelper().runTest(testFileName: "LinkTitlesWithEmbeddedQuotes")
    }

    func testReferenceLinkWithIDOnNextLine() {
        TestHelper().runTest(testFileName: "ReferenceLinkWithIDOnNextLine")
    }

}
