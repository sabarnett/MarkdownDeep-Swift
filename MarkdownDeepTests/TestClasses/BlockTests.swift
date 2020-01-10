// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest
@testable import MarkdownDeep

class BlockTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

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
}
