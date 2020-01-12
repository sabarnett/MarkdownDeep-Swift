// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//
// incorporating BlockProcessorTests from the cs project
//

import XCTest
@testable import MarkdownDeep

class BlockTests: XCTestCase {

    var p: BlockProcessor? = nil;

    override func setUp() {
        p = BlockProcessor(Markdown(), false)
    }

    override func tearDown() {
    }

    // MARK:- Resource based tests

    func testCodeBlocks() {
        TestHelper().runTest(testFileName: "CodeBlocks")
    }

    func testAtxHeadings() {
        TestHelper().runTest(testFileName: "AtxHeadings")
    }

    func testComplexListItems() {
        TestHelper().runTest(testFileName: "ComplexListItems", showDebugInfo: true)
    }

    func testHardWrappedListItems() {
        TestHelper().runTest(testFileName: "HardWrappedListItems", showDebugInfo: true)
    }

    func testHardWrappedParagraph() {
        TestHelper().runTest(testFileName: "HardWrappedParagraph", showDebugInfo: true)
    }

    func testHardWrappedParagraphInListItem() {
        TestHelper().runTest(testFileName: "HardWrappedParagraphInListItem", showDebugInfo: true)
    }

    func testHardWrappedParagraphWithListLikeLine() {
        TestHelper().runTest(testFileName: "HardWrappedParagraphWithListLikeLine", showDebugInfo: true)
    }

    func testHtmlAttributeWithoutValue() {
        TestHelper().runTest(testFileName: "HtmlAttributeWithoutValue", showDebugInfo: true)
    }

    func testHtmlBlock() {
        TestHelper().runTest(testFileName: "HtmlBlock", showDebugInfo: true)
    }

    func testHtmlComments() {
        TestHelper().runTest(testFileName: "HtmlComments", showDebugInfo: true)
    }

    func testInsTypes() {
        TestHelper().runTest(testFileName: "InsTypes", showDebugInfo: true)
    }

    func testMultipleParagraphs() {
        TestHelper().runTest(testFileName: "MultipleParagraphs", showDebugInfo: true)
    }

    func testNestedListItems() {
        TestHelper().runTest(testFileName: "NestedListItems", showDebugInfo: true)
    }

    func testParagraphBreaks() {
        TestHelper().runTest(testFileName: "ParagraphBreaks", showDebugInfo: true)
    }

    func testPartiallyIndentedLists() {
        TestHelper().runTest(testFileName: "PartiallyIndentedLists", showDebugInfo: true)
    }

    func testQuoteBlocks() {
        TestHelper().runTest(testFileName: "QuoteBlocks", showDebugInfo: true)
    }

    func testQuoteBlocksNested() {
        TestHelper().runTest(testFileName: "QuoteBlocksNested", showDebugInfo: true)
    }

    func testSetExtHeadings() {
        TestHelper().runTest(testFileName: "SetExtHeadings", showDebugInfo: true)
    }

    func testSimpleOrderedList() {
        TestHelper().runTest(testFileName: "SimpleOrderedList", showDebugInfo: true)
    }

    func testSimpleParagraph() {
        TestHelper().runTest(testFileName: "SimpleParagraph", showDebugInfo: true)
    }

    func testSimpleUnorderedList() {
        TestHelper().runTest(testFileName: "SimpleUnorderedList", showDebugInfo: true)
    }

    // MARK:- Explicit tests

    func testSingleLineParagraph() {
        let b = p!.process("paragraph")

        XCTAssertEqual(1, b.count);
        XCTAssertEqual(BlockType.p, b[0].blockType);
        XCTAssertEqual("paragraph", b[0].content);
    }

    func testMultilineParagraph() {
        let b = p!.process("l1\nl2\n\n")

        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.p, b[0].blockType)
        XCTAssertEqual("l1\nl2", b[0].content)
    }

    func testSetExH1() {
        let b = p!.process("heading\n===\n\n")

        XCTAssertEqual(1, b.count);
        XCTAssertEqual(BlockType.h1, b[0].blockType);
        XCTAssertEqual("heading", b[0].content);
    }

    func testSetExH2() {
        let b = p!.process("heading\n---\n\n")

        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.h2, b[0].blockType)
        XCTAssertEqual("heading", b[0].content)
    }

    func testSetExtHeadingInParagraph() {
        let b = p!.process("p1\nheading\n---\np2\n")
        XCTAssertEqual(3, b.count)

        XCTAssertEqual(BlockType.p, b[0].blockType)
        XCTAssertEqual("p1", b[0].content)

        XCTAssertEqual(BlockType.h2, b[1].blockType)
        XCTAssertEqual("heading", b[1].content)

        XCTAssertEqual(BlockType.p, b[2].blockType)
        XCTAssertEqual("p2", b[2].content)
    }

    func testAtxHeaders() {
        let b = p!.process("#heading#\nparagraph\n")
        XCTAssertEqual(2, b.count)

        XCTAssertEqual(BlockType.h1, b[0].blockType)
        XCTAssertEqual("heading", b[0].content)

        XCTAssertEqual(BlockType.p, b[1].blockType)
        XCTAssertEqual("paragraph", b[1].content)
    }

    func testAtxHeadingInParagraph() {
        let b = p!.process("p1\n## heading ##\np2\n")

        XCTAssertEqual(3, b.count)

        XCTAssertEqual(BlockType.p, b[0].blockType)
        XCTAssertEqual("p1", b[0].content)

        XCTAssertEqual(BlockType.h2, b[1].blockType)
        XCTAssertEqual("heading", b[1].content)

        XCTAssertEqual(BlockType.p, b[2].blockType)
        XCTAssertEqual("p2", b[2].content)
    }

    func testCodeBlock() {
        let b = p!.process("\tcode1\n\t\tcode2\n\tcode3\nparagraph")
        XCTAssertEqual(2, b.count)

        let cb: Block = b[0];
        XCTAssertEqual("code1\n\tcode2\ncode3\n", cb.content)

        XCTAssertEqual(BlockType.p, b[1].blockType)
        XCTAssertEqual("paragraph", b[1].content)
    }

    func testHtmlBlockText() {
        let b = p!.process("<div>\n</div>\n")

        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.html, b[0].blockType)
        XCTAssertEqual("<div>\n</div>\n", b[0].content)
    }

    func testHtmlCommentBlock() {
        let b = p!.process("<!-- this is a\ncomments -->\n")

        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.html, b[0].blockType)
        XCTAssertEqual("<!-- this is a\ncomments -->\n", b[0].content)
    }

    func testHorizontalRules() {
        var b = p!.process("---\n")
        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.hr, b[0].blockType)

        b = p!.process("___\n")
        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.hr, b[0].blockType)

        b = p!.process("***\n")
        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.hr, b[0].blockType)

        b = p!.process(" - - - \n")
        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.hr, b[0].blockType)

        b = p!.process("  _ _ _ \n")
        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.hr, b[0].blockType)

        b = p!.process(" * * * \n")
        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.hr, b[0].blockType)    }
}
