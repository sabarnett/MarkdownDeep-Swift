// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest
@testable import MarkdownDeep

class HeadingTests: XCTestCase {

    private var md: Markdown = Markdown();

    override func setUp() {
        md = Markdown()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testHead1() {
        let testString = "# Heading 1"
        let expectedResult = "<h1>Heading 1</h1>\n"
        let actualResult = md.transform(testString)

        XCTAssertEqual(expectedResult, actualResult)
    }

    func testHead2() {
        let testString = "## Heading 2"
        let expectedResult = "<h2>Heading 2</h2>\n"
        let actualResult = md.transform(testString)

        XCTAssertEqual(expectedResult, actualResult)
    }

    func testHead3() {
        let testString = "### Heading 3"
        let expectedResult = "<h3>Heading 3</h3>\n"
        let actualResult = md.transform(testString)

        XCTAssertEqual(expectedResult, actualResult)
    }

    func testHead4() {
        let testString = "#### Heading 4"
        let expectedResult = "<h4>Heading 4</h4>\n"
        let actualResult = md.transform(testString)

        XCTAssertEqual(expectedResult, actualResult)
    }

    func testHead5() {
        let testString = "##### Heading 5"
        let expectedResult = "<h5>Heading 5</h5>\n"
        let actualResult = md.transform(testString)

        XCTAssertEqual(expectedResult, actualResult)
    }

    func testHead6() {
        let testString = "###### Heading 6"
        let expectedResult = "<h6>Heading 6</h6>\n"
        let actualResult = md.transform(testString)

        XCTAssertEqual(expectedResult, actualResult)
    }

    func testHead7() {
        let testString = "####### Heading 7"
        let expectedResult = "<h6>Heading 7</h6>\n"
        let actualResult = md.transform(testString)

        XCTAssertEqual(expectedResult, actualResult)
    }

}
