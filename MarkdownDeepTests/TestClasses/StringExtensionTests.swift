// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest
@testable import MarkdownDeep

class StringExtensionTests: XCTestCase {

    func testIsNullOrEmpty() {
        var testString: String? = nil
        XCTAssertTrue(String.isNullOrEmpty(testString))

        testString = ""
        XCTAssertTrue(String.isNullOrEmpty(testString))

        testString = " "
        XCTAssertFalse(String.isNullOrEmpty(testString))
    }

    func testTrimWhitespace() {
        let testString = "Test1"
        XCTAssertEqual(testString.trimWhitespace(), testString)

        let testString2 = "  " + testString + "  "
        XCTAssertEqual(testString2.trimWhitespace(), testString)
    }

    func testStartsWithWhitespace() {
        let testString = "Test1"
        XCTAssertFalse(testString.startsWithWhiteSpace())

        let testString2 = " Test2"
        XCTAssertTrue(testString2.startsWithWhiteSpace())
    }

    func testSubStringFromFor() {
        let testString = "This is a test string"

        var substring = testString.substring(from: 5, for: 2)
        XCTAssertEqual(substring, "is")

        substring = testString.substring(from: 0, for: 4)
        XCTAssertEqual(substring, "This")

        substring = testString.substring(from: testString.count, for: 4)
        XCTAssertEqual(substring, "")

        substring = testString.substring(from: testString.count - 1, for: 4)
        XCTAssertEqual(substring, "g")
    }

    func testSubstringNsRange() {
        let testString = "This is a test string"
        let range = NSRange(location: 10, length: 4)

        XCTAssertEqual(testString.substring(with: range), "test")
    }

    func testLeft() {
        let testString = "This is a test"
        XCTAssertEqual(testString.left(count: 7), "This is")

        let testString2 = "This"
        XCTAssertEqual(testString2.left(count: testString2.count + 1), "This")
    }

    func testRight() {
        let testString = "This is a test"
        XCTAssertEqual(testString.right(from: 10), "test")

        let testString2 = "Test"
        XCTAssertEqual(testString2.right(from: testString2.count + 1), "")

        XCTAssertEqual(testString.right(count: 6), "a test")
        XCTAssertEqual(testString.right(count: testString.count + 1), testString)
    }

    func testCharAt() {
        let testString = "This is a test string"
        XCTAssertEqual(testString.charAt(at: 0), "T")
        XCTAssertEqual(testString.charAt(at: testString.count - 1), "g")
        XCTAssertEqual(testString.charAt(at: 5), "i")
    }

    func testIndexOfString() {
        let testString = "This Is A Test String"

        XCTAssertEqual(testString.indexOf(str: "is a", caseInsensitive: true), 5)
        XCTAssertEqual(testString.indexOf(str: "is a", startPos: 6, caseInsensitive: true), -1)
        XCTAssertEqual(testString.indexOf(str: "is a", caseInsensitive: false), -1)
    }

    func testIndexOfChar() {
        let testString = "This is a test string"

        XCTAssertEqual(testString.indexOf(ch: "a"), 8)
        XCTAssertEqual(testString.indexOf(ch: "z"), -1)
        XCTAssertEqual(testString.indexOf(ch: "s", startPos: 4), 6)
    }

    func testIndexOfAnyChar() {
        let testString = "This is a test string"

        var testChars: [Character] = ["s", "a", "z"]
        XCTAssertEqual(testString.indexOfAny(ch: testChars), 3)
        XCTAssertEqual(testString.indexOfAny(ch: testChars, startPos: 9), 12)

        XCTAssertNotEqual(testString.indexOfAny(ch: testChars), 4)
        XCTAssertNotEqual(testString.indexOfAny(ch: testChars, startPos: 9), 11)

        testChars = ["x", "y"]
        XCTAssertEqual(testString.indexOfAny(ch: testChars), -1)
    }

    func testGetRange() {
        let testString = "This is a test string"

        let range = testString.nsrange
        XCTAssertEqual(range.length, testString.count)
        XCTAssertEqual(range.location, 0)
    }
}
