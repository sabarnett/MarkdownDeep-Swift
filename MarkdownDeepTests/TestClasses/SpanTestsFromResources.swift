// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//
// Incorporating CodeSpanTests from the cs project
//

import XCTest
@testable import MarkdownDeep

class SpanTestsFromResources: XCTestCase {

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
