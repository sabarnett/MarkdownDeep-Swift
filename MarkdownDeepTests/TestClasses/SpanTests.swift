// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//
// Incorporating CodeSpanTests from the cs project
//

import XCTest
@testable import MarkdownDeep

class SpanTests: XCTestCase {

    var f: SpanFormatter? = nil

    override func setUp() {
        f = SpanFormatter(Markdown())
    }

    // MARK:- Resource based tests

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

    // MARK:- String based tests

    func testSingleTick() {
        XCTAssertEqual("pre <code>code span</code> post",
                f!.format("pre `code span` post"))
    }

    func testSingleTickWithSpaces() {
        XCTAssertEqual("pre <code>code span</code> post",
                f!.format("pre ` code span ` post"))
    }

    func testMultiTick() {
        XCTAssertEqual("pre <code>code span</code> post",
                f!.format("pre ````code span```` post"))
    }

    func testMultiTickWithEmbeddedTicks() {
        XCTAssertEqual("pre <code>`code span`</code> post",
                f!.format("pre ```` `code span` ```` post"))
    }

    func testContentEncoded() {
        XCTAssertEqual("pre <code>&lt;div&gt;</code> post",
                f!.format("pre ```` <div> ```` post"))
        XCTAssertEqual("pre <code>&amp;amp;</code> post",
                f!.format("pre ```` &amp; ```` post"))
    }
}
