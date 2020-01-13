// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import Foundation
import XCTest
@testable import MarkdownDeep

class TestHelper: XCTestCase {

    public func runTest(testFileName: String, showDebugInfo: Bool = false) {
        let bundle: Bundle = Bundle(for: type(of: self))

        let testName = testFileName

        // Test file with have .txt extension and expected result file will have
        // .html extension. Load both files
        let testString = readTestFile(inBundle: bundle, forTest: testFileName)
        let resultString = readExpectedResults(inBundle: bundle, forTest: testFileName)

        // Create a markdown instance for the test. Based on the file name,
        // set any options the test is going to require.
        let markdown = createMarkdown(forFile: testFileName)

        // Optionally print debugging information
        if showDebugInfo {
            showPreDebuggingInfo(testInput: testString, expectedOutput: resultString)
        }

        // Actually run the test and get the results back
        let testResult = runMarkdownTest(md: markdown, forTest: testFileName, testData: testString)

        // Optionally print debugging information
        if showDebugInfo {
            showPostDebuggingInfo(testInput: testString, expectedOutput: resultString, actualOutput: testResult)
        }

        XCTAssertEqual(testResult, resultString)

        print("Test completed: " + testName)
    }

    public static func stripRedundantWhitespace(_ inputString: String) -> String {

        let si = inputString.replacingOccurrences(of: "\r\n", with: "\n")
        let siLength = si.count
        var sb = ""

        var index: Int = 0
        while index < si.count {
            var ch = char(at: index, in: si)

            switch ch {
            case " ", "\t", "\r", "\n":
                index += 1

                while index < siLength {
                    ch = char(at: index, in: si)
                    if ch != " " && ch != "\t" && ch != "\r" && ch != "\n" {
                        break
                    }

                    index += 1
                }

                if index < siLength && char(at: index, in: si) != "<" {
                    sb.append(" ")
                }

            case ">":
                sb.append("> ")
                index += 1

                while index < siLength {
                    ch = char(at: index, in: si)
                    if ch != " " && ch != "\t" && ch != "\r" && ch != "\n" {
                        break
                    }

                    index += 1
                }

            case "<":
                if (index + 5) < siLength && substring(at: index, for: 5, in: si) == "<pre>" {
                    sb.append(" ")

                    var end = indexOf(text: "</pre>", from: index, in: si)
                    if end < 0 {
                        end = siLength
                    }

                    sb.append(substring(at: index, for: end-index, in: si))
                    sb.append(" ")

                    index = end
                } else {
                    sb.append(" <")
                    index += 1
                }

            default:
                sb.append(ch!)
                index += 1
                break;
            }
        }

        return sb.trimWhitespace()
    }



    // MARK: Helper Functions

    private func createMarkdown(forFile testFileName: String) -> Markdown {
        let markdown = Markdown()

        if testFileName.contains("(SafeMode)") {
            print("Safe Mode set")
            markdown.SafeMode = true
        }

        if testFileName.contains("(ExtraMode)") {
            print("Extra Mode set")
            markdown.ExtraMode = true
        }

        if (testFileName.contains("(MarkdownInHtml)")) {
            print("Markdown in HTML set")
            markdown.MarkdownInHtml = true
        }

        if (testFileName.contains("(AutoHeadingIDs)")) {
            print("Auto Heading ids set")
            markdown.AutoHeadingIDs = true
        }

        return markdown
    }

    public func readTestFile(inBundle: Bundle, forTest: String) -> String {
        let testPath = inBundle.path(forResource: forTest, ofType: "txt")!
        return try! String(contentsOfFile: testPath)
    }

    private func readExpectedResults(inBundle: Bundle, forTest: String) -> String {
        let resultPath = inBundle.path(forResource: forTest, ofType: "html")!
        let resultStringFromFile = try! String(contentsOfFile: resultPath)
        return TestHelper.stripRedundantWhitespace(resultStringFromFile)
    }

    private func runMarkdownTest(md: Markdown, forTest: String, testData: String) -> String {
        print("Running test: " + forTest)
        let testResultFromMarkdown = md.transform(testData)
        return TestHelper.stripRedundantWhitespace(testResultFromMarkdown)
    }

    private func showPreDebuggingInfo(testInput: String,
                                   expectedOutput: String) {
        print("TestString: -------------------------")
        print(testInput)
    }

    private func showPostDebuggingInfo(testInput: String,
                                   expectedOutput: String,
                                   actualOutput: String) {
        print("TestString: -------------------------")
        print(testInput)

        print("ExpectedResult ------------------------- " + String(expectedOutput.count))
        print(expectedOutput)

        print("ActualResult -------------------------" + String(actualOutput.count))
        print(actualOutput)
    }
    private static func char(at index: Int, in st: String) -> Character! {

        let indexStartOfText = st.index(st.startIndex, offsetBy: index)
        guard indexStartOfText < st.endIndex else { return nil }

        let indexEndOfText = indexStartOfText

        let substring1 = st[indexStartOfText...indexEndOfText]

        return substring1.first
    }

    private static func substring(at start: Int, for length: Int, in st: String) -> String {

        guard start < st.count else { return "" }

        // If the start offset plus the requested length is longer than
        // the string, trim the length to the remaining characters
        var extractLength = length
        if (start + length > st.count) {
            extractLength = st.count - start
        }

        let indexStartOfText = st.index(st.startIndex, offsetBy: start)
        let indexEndOfText = st.index(st.startIndex, offsetBy: start + extractLength - 1)

        let substring1 = st[indexStartOfText...indexEndOfText]
        return String(substring1)
    }

    private static func indexOf(text str: String, from startPos: Int, in inStr: String) -> Int {

        let testLength = str.count
        let testString = str.lowercased()
        let thisString = inStr.lowercased()

        for index in startPos ... inStr.count - testLength {
            if testString == substring(at: index, for: testLength, in: thisString) {
                return index
            }
        }

        return -1
    }
}
