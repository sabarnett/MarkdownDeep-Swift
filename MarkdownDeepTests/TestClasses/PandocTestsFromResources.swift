// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest

class PandocTestsFromResources: XCTestCase {

    func testAmps_and_angle_encoding() {
        TestHelper().runTest(testFileName: "md11_Amps_and_angle_encoding")
    }

    func testFailure_to_escape_less_than() {
        TestHelper().runTest(testFileName: "pandocfailure-to-escape-less-than")
    }

    func testNested_divs() {
        TestHelper().runTest(testFileName: "pandocnested-divs")
    }

    func testNested_emphasis() {
        TestHelper().runTest(testFileName: "pandocnested-emphasis")
    }

    func testUnordered_list_followed_by_ordered_list() {
        TestHelper().runTest(testFileName: "pandocunordered-list-followed-by-ordered-list")
    }

}
