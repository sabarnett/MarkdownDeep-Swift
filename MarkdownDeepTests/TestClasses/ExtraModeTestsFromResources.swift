// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest

class ExtraModeTestsFromResources: XCTestCase {

    func testAbbreviationsExtraMode() {
        TestHelper().runTest(testFileName: "Abbreviations(ExtraMode)", showDebugInfo: true)
    }

    func testBackslashExcapesExtraMode() {
        TestHelper().runTest(testFileName: "BackslashEscapes(ExtraMode)", showDebugInfo: true)
    }

    func testDefinitionListsExtraMode() {
        TestHelper().runTest(testFileName: "DefinitionLists(ExtraMode)", showDebugInfo: true)
    }

    func testEmphasisExtraMode() {
        TestHelper().runTest(testFileName: "Emphasis(ExtraMode)", showDebugInfo: true)
    }

    func testFencedCodeBlocksExtraMode() {
        TestHelper().runTest(testFileName: "FencedCodeBlocks(ExtraMode)", showDebugInfo: true)
    }

    func testFencedCodeBlocksAltExtraMode() {
        TestHelper().runTest(testFileName: "FencedCodeBlocksAlt(ExtraMode)", showDebugInfo: true)
    }

    func testFootnotesExtraMode() {
        TestHelper().runTest(testFileName: "Footnotes(ExtraMode)", showDebugInfo: true)
    }

    func testHeaderIDsExtraMode() {
        TestHelper().runTest(testFileName: "HeaderIDs(ExtraMode)", showDebugInfo: true)
    }

    func testHeaderIdsExtraModeAutoHead() {
        TestHelper().runTest(testFileName: "HeaderIDs(ExtraMode)(AutoHeadingIDs)", showDebugInfo: true)
    }

    func testIssue12ExtraMode() {
        TestHelper().runTest(testFileName: "Issue12(ExtraMode)", showDebugInfo: true)
    }

    func testIssue26ExtraMode() {
        TestHelper().runTest(testFileName: "Issue26(ExtraMode)", showDebugInfo: true)
    }

    func testIssue30ExtraMode() {
        TestHelper().runTest(testFileName: "Issue30(ExtraMode)", showDebugInfo: true)
    }

    func testMarkdownInHtmlDeepNestedExtraMode() {
        TestHelper().runTest(testFileName: "MarkdownInHtml-DeepNested(ExtraMode)", showDebugInfo: true)
    }

    func testMarkdownInHtmlDeepNestedExtraModeMDInHtml() {
        TestHelper().runTest(testFileName: "MarkdownInHtml-DeepNested(ExtraMode)(MarkdownInHtml)", showDebugInfo: true)
    }

    func testMarkdownInHtmlNestedExtraMode() {
        TestHelper().runTest(testFileName: "MarkdownInHtml-Nested(ExtraMode)", showDebugInfo: true)
    }

    func testMarkdownInHtmlExtraMode() {
        TestHelper().runTest(testFileName: "MarkdownInHtml(ExtraMode)", showDebugInfo: true)
    }

    func testTableAlignmentExtraMode() {
        TestHelper().runTest(testFileName: "TableAlignment(ExtraMode)", showDebugInfo: true)
    }

    func testTableFormattingExtraMode() {
        TestHelper().runTest(testFileName: "TableFormatting(ExtraMode)", showDebugInfo: true)
    }

    func testTablesExtraMode() {
        TestHelper().runTest(testFileName: "Tables(ExtraMode)", showDebugInfo: true)
    }

}
