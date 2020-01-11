// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest

class PandocTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAmps_and_angle_encoding() {
        TestHelper().runTest(testFileName: "md11_Amps_and_angle_encoding")
    }


    func testFailure_to_escape_less_than() {
        TestHelper().runTest(testFileName: "pandocfailure-to-escape-less-than")
    }

    func testIndented_code_in_list_item() {
        TestHelper().runTest(testFileName: "pandocindented-code-in-list-item", showDebugInfo: true)
    }

    func testNested_divs() {
        TestHelper().runTest(testFileName: "pandocnested-divs")
    }

    func testNested_emphasis() {
        TestHelper().runTest(testFileName: "pandocnested-emphasis")
    }

    func testUnordered_list_and_horizontal_rules() {
        TestHelper().runTest(testFileName: "pandocunordered-list-and-horizontal-rules", showDebugInfo: true)
    }
    func testUnordered_list_followed_by_ordered_list() {
        TestHelper().runTest(testFileName: "pandocunordered-list-followed-by-ordered-list")
    }

    func testUnpredictable_sublists() {
        TestHelper().runTest(testFileName: "pandocunpredictable-sublists", showDebugInfo: true)
    }
}
