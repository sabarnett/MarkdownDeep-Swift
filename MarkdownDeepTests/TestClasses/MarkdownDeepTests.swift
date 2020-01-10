// Project: MarkdownDeep
//
// Copyright © 2019 Steven Barnett. All rights reserved. 
//

import XCTest
@testable import MarkdownDeep

class MarkdownDeepTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreateMarkdownClass() {
        let md = Markdown()
        XCTAssertNotNil(md)
    }

    func testBasicTestSinglePara() {
        let testString = "This is a test string"
        let expectedResult = "<p>This is a test string</p>\n"
        let resultString = Markdown().transform(testString)

        XCTAssertEqual(resultString, expectedResult)
    }

    func testBasicTestSingleParaMultiLine() {
        let testString = "This is a test string\nwhich continues on to a second line"
        let expectedResult = "<p>This is a test string\nwhich continues on to a second line</p>\n"
        let resultString = Markdown().transform(testString)

        XCTAssertEqual(resultString, expectedResult)
    }

    func testBasicTestTwoPara() {
        let testString = "This is a test string\n\nThis is also a test string"
        let expectedResult = "<p>This is a test string</p>\n<p>This is also a test string</p>\n"
        let resultString = Markdown().transform(testString)

        XCTAssertEqual(resultString, expectedResult)
    }

    func testBasicTestThreePara() {
        let testString = "This is a test string\n\nThis is also a test string\n\nAnd a final para"
        let expectedResult = "<p>This is a test string</p>\n<p>This is also a test string</p>\n<p>And a final para</p>\n"
        let resultString = Markdown().transform(testString)

        XCTAssertEqual(resultString, expectedResult)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
