// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//
// incorporating BlockProcessorTests from the cs project
//

import XCTest
@testable import MarkdownDeep

class BlockTestsFromResources: XCTestCase {

    func testCodeBlocks() {
        TestHelper().runTest(testFileName: "CodeBlocks")
    }

    func testAtxHeadings() {
        TestHelper().runTest(testFileName: "AtxHeadings")
    }

    func testComplexListItems() {
        TestHelper().runTest(testFileName: "ComplexListItems")
    }

    func testHardWrappedListItems() {
        TestHelper().runTest(testFileName: "HardWrappedListItems")
    }

    func testHardWrappedParagraph() {
        TestHelper().runTest(testFileName: "HardWrappedParagraph")
    }

    func testHardWrappedParagraphInListItem() {
        TestHelper().runTest(testFileName: "HardWrappedParagraphInListItem")
    }

    func testHardWrappedParagraphWithListLikeLine() {
        TestHelper().runTest(testFileName: "HardWrappedParagraphWithListLikeLine")
    }

    func testHtmlAttributeWithoutValue() {
        TestHelper().runTest(testFileName: "HtmlAttributeWithoutValue")
    }

    func testHtmlBlock() {
        TestHelper().runTest(testFileName: "HtmlBlock")
    }

    func testHtmlComments() {
        TestHelper().runTest(testFileName: "HtmlComments")
    }

    func testInsTypes() {
        TestHelper().runTest(testFileName: "InsTypes")
    }

    func testMultipleParagraphs() {
        TestHelper().runTest(testFileName: "MultipleParagraphs")
    }

    func testNestedListItems() {
        TestHelper().runTest(testFileName: "NestedListItems")
    }

    func testParagraphBreaks() {
        TestHelper().runTest(testFileName: "ParagraphBreaks")
    }

    func testPartiallyIndentedLists() {
        TestHelper().runTest(testFileName: "PartiallyIndentedLists")
    }

    func testQuoteBlocks() {
        TestHelper().runTest(testFileName: "QuoteBlocks")
    }

    func testQuoteBlocksNested() {
        TestHelper().runTest(testFileName: "QuoteBlocksNested")
    }

    func testSetExtHeadings() {
        TestHelper().runTest(testFileName: "SetExtHeadings")
    }

    func testSimpleOrderedList() {
        TestHelper().runTest(testFileName: "SimpleOrderedList")
    }

    func testSimpleParagraph() {
        TestHelper().runTest(testFileName: "SimpleParagraph")
    }

    func testSimpleUnorderedList() {
        TestHelper().runTest(testFileName: "SimpleUnorderedList")
    }
}
