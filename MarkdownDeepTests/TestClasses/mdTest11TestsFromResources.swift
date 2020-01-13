// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest

class mdTest11TestsFromResources: XCTestCase {

    func testAmps_and_angle_encoding() {
        TestHelper().runTest(testFileName: "md11_Amps_and_angle_encoding")
    }

    func testAuto_links() {
        TestHelper().runTest(testFileName: "md11_Auto_links")
    }

    func testBackslash_escapes() {
        TestHelper().runTest(testFileName: "md11_Backslash_escapes")
    }

    func testBlockquotes_with_code_blocks() {
        TestHelper().runTest(testFileName: "md11_Blockquotes_with_code_blocks")
    }

    func testCode_Blocks() {
        TestHelper().runTest(testFileName: "md11_Code_Blocks")
    }

    func testCode_Spans() {
        TestHelper().runTest(testFileName: "md11_Code_Spans")
    }

    func testHard_wrapped_paragraphs_with_list_like_lines() {
        TestHelper().runTest(testFileName: "md11_Hard_wrapped_paragraphs_with_list_like_lines")
    }

    func testHorizontal_rules() {
        TestHelper().runTest(testFileName: "md11_Horizontal_rules")
    }

    func testImages() {
        TestHelper().runTest(testFileName: "md11_Images")
    }

    func testInline_HTML_Advanced() {
        TestHelper().runTest(testFileName: "md11_Inline_HTML_Advanced")
    }

    func testInline_HTML_comments() {
        TestHelper().runTest(testFileName: "md11_Inline_HTML_comments")
    }

    func testInline_HTML_Simple() {
        TestHelper().runTest(testFileName: "md11_Inline_HTML_Simple")
    }

    func testLinks_inline_style() {
        TestHelper().runTest(testFileName: "md11_Links_inline_style")
    }

    func testLinks_reference_style() {
        TestHelper().runTest(testFileName: "md11_Links_reference_style")
    }

    func testLinks_shortcut_references() {
        TestHelper().runTest(testFileName: "md11_Links_shortcut_references")
    }

    func testLiteral_quotes_in_titles() {
        TestHelper().runTest(testFileName: "md11_Literal_quotes_in_titles")
    }

    func testMarkdown_Documentation_Basics() {
        TestHelper().runTest(testFileName: "md11_Markdown_Documentation_Basics")
    }

    func testMarkdown_Documentation_Syntax() {
        TestHelper().runTest(testFileName: "md11_Markdown_Documentation_Syntax")
    }

    func testNested_blockquotes() {
        TestHelper().runTest(testFileName: "md11_Nested_blockquotes")
    }

    func testOrdered_and_unordered_lists() {
        TestHelper().runTest(testFileName: "md11_Ordered_and_unordered_lists")
    }

    func testStrong_and_em_together() {
        TestHelper().runTest(testFileName: "md11_Strong_and_em_together")
    }

    func testTabs() {
        TestHelper().runTest(testFileName: "md11_Tabs")
    }

    func testTidyness() {
        TestHelper().runTest(testFileName: "md11_Tidyness")
    }
}
