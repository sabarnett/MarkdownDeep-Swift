// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest
@testable import MarkdownDeep

class XssAttackTests: XCTestCase {

    func isTagReallySafe(tag: HtmlTag) -> Bool
    {
        switch (tag.name.uppercased())
        {
        case "IMG":
            return true
        case "B", "UL", "LI", "I":
            return tag.attributes.count == 0;

        case "A", "a":
            return tag.closing && tag.attributes.count == 0;

        default:
            return false
        }
    }

    func readTestData(fromFile: String) -> [String] {
        let helper = TestHelper()
        let bundle: Bundle = Bundle(for: type(of: self))

        let fileData = helper.readTestFile(inBundle: bundle, forTest: fromFile).replacingOccurrences(of: "\r\n", with: "\n")
        let lineData = fileData.split(separator: "\n", omittingEmptySubsequences: false)

        // We now have an array of lines containing the test data. Some of that
        // data needs to be stripped, so we do that next
        var parseString = ""
        var strings: [String] = []
        for testLine in lineData {
            let line = String(testLine)

            // Drop comment lines
            if line.hasPrefix("////") {
                continue
            }

            // Terminator indicator
            if line.hasPrefix("======") {
                break
            }

            // Drop balnk lines
            let trimmedLine = line.trimmingCharacters(in: CharacterSet.whitespaces)
            if trimmedLine.count == 0 {
                if parseString.count != 0 {
                    strings.append(parseString)
                }
                parseString = ""
                continue
            }

            if parseString.count == 0 {
                parseString = String(line)
            } else {
                parseString = parseString + "\n" + String(line)
            }
        }

        if parseString.count != 0 {
            strings.append(parseString)
        }

        return strings
    }

    func testAttacks() {
        let testStrings = readTestData(fromFile: "xss_attacks")
        print("There are \(testStrings.count) tests in this file.")

        for testString in testStrings {
            print("Testing: " + testString)
            let p: StringScanner = StringScanner(testString)
            while !p.eof {
                let tag = HtmlTag.parse(scanner: p)
                if tag != nil {
                    if tag!.isSafe() {
                        XCTAssertTrue(isTagReallySafe(tag: tag!))
                    }
                } else {
                    p.skipForward(1)
                }
            }

        }
    }

    func testNonAttacks() {
        let testStrings = readTestData(fromFile: "non_attacks")

        for testString in testStrings {
            let p: StringScanner = StringScanner(testString)
            while !p.eof {
                let tag = HtmlTag.parse(scanner: p)
                if tag != nil {
                    XCTAssertTrue(tag!.isSafe())
                } else {
                    p.skipForward(1)
                }
            }
        }
    }
}
