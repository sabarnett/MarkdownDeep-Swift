// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest

class mdTest01TestsFromResources: XCTestCase {

    func testCodeInsideList() {
        TestHelper().runTest(testFileName: "code-inside-list")
    }

    func testLineEndingsCR() {
        TestHelper().runTest(testFileName: "line-endings-cr")
    }

    func testLineEndingsCRLF() {
        TestHelper().runTest(testFileName: "line-endings-crlf")
    }

    func testLineEndingsLF() {
        TestHelper().runTest(testFileName: "line-endings-lf")
    }

    func testMarkdownReadme() {
        TestHelper().runTest(testFileName: "markdown-readme")
    }
}
