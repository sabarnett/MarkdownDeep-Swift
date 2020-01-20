// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest

class ExtraModeTestsFromResources: XCTestCase {

    func testAbbreviationsExtraMode() {
        TestHelper().runTest(testFileName: "Abbreviations(ExtraMode)")
    }

    func testBackslashExcapesExtraMode() {
        TestHelper().runTest(testFileName: "BackslashEscapes(ExtraMode)")
    }

    func testDefinitionListsExtraMode() {
        TestHelper().runTest(testFileName: "DefinitionLists(ExtraMode)")
    }

    func testEmphasisExtraMode() {
        TestHelper().runTest(testFileName: "Emphasis(ExtraMode)")
    }

    func testFencedCodeBlocksExtraMode() {
        TestHelper().runTest(testFileName: "FencedCodeBlocks(ExtraMode)")
    }

    func testFencedCodeBlocksAltExtraMode() {
        TestHelper().runTest(testFileName: "FencedCodeBlocksAlt(ExtraMode)")
    }

    func testFootnotesExtraMode() {
        TestHelper().runTest(testFileName: "Footnotes(ExtraMode)")
    }

    func testHeaderIDsExtraMode() {
        TestHelper().runTest(testFileName: "HeaderIDs(ExtraMode)")
    }

    func testHeaderIdsExtraModeAutoHead() {
        TestHelper().runTest(testFileName: "HeaderIDs(ExtraMode)(AutoHeadingIDs)")
    }

    func testIssue12ExtraMode() {
        TestHelper().runTest(testFileName: "Issue12(ExtraMode)")
    }

    func testIssue26ExtraMode() {
        TestHelper().runTest(testFileName: "Issue26(ExtraMode)")
    }

    func testIssue30ExtraMode() {
        TestHelper().runTest(testFileName: "Issue30(ExtraMode)")
    }

    func testMarkdownInHtmlDeepNestedExtraMode() {
        TestHelper().runTest(testFileName: "MarkdownInHtml-DeepNested(ExtraMode)")
    }

    func testMarkdownInHtmlDeepNestedExtraModeMDInHtml() {
        TestHelper().runTest(testFileName: "MarkdownInHtml-DeepNested(ExtraMode)(MarkdownInHtml)")
    }

    func testMarkdownInHtmlNestedExtraMode() {
        TestHelper().runTest(testFileName: "MarkdownInHtml-Nested(ExtraMode)")
    }

    func testMarkdownInHtmlExtraMode() {
        TestHelper().runTest(testFileName: "MarkdownInHtml(ExtraMode)")
    }

    func testTableAlignmentExtraMode() {
        TestHelper().runTest(testFileName: "TableAlignment(ExtraMode)")
    }

    func testTableFormattingExtraMode() {
        TestHelper().runTest(testFileName: "TableFormatting(ExtraMode)")
    }

    func testTablesExtraMode() {
        TestHelper().runTest(testFileName: "Tables(ExtraMode)")
    }

}
