// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest

class mdTest01Tests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

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
