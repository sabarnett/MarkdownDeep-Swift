//
//  MarkdownDeep for SWIFT
//     Copyright (C) 2020 Steven Barnett
//
//  This is a port of the C# version of MarkdownDeep...
//
//   MarkdownDeep - http://www.toptensoftware.com/markdowndeep
//     Copyright (C) 2010-2011 Topten Software
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this product except in compliance with the
//   License. You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing,
//   software distributed under the License is distributed on
//   an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//   either express or implied. See the License for the specific
//   language governing permissions and limitations under the License.
//

import Foundation

extension String {

    /// Returns an NSRange instance covering the whole string
    var nsrange: NSRange {
        return NSRange(location: 0, length: utf16.count)
    }

    /// Returns True if the string under test is nil or has no content. Any
    /// whitespace is assumed to be content.
    ///
    /// - Parameter value: The (optional) string to be tested.
    static func isNullOrEmpty(_ value: String!) -> Bool {
        if (value == nil) {
            return true
        }

        if (value!.count == 0) {
            return true
        }
        
        return false
    }

    /// Trims whitespave and newlines from a string, returning a new string.
    func trimWhitespace() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns True if the string starts with whitespace character(s) else false
    func startsWithWhiteSpace() -> Bool {
        let ch = self.first;
        if (ch == nil) {
            return false;
        }

        return ch!.isWhitespace;
    }


    /// Extracts a sub-string from an existing string starting at the specified
    /// start character index and for the number of characters. Returns a new
    /// string
    ///
    /// - Parameters:
    ///   - start: The start offset of the string to be extracted
    ///   - length: The number of characters to extract
    ///
    /// - Returns:
    /// Returns the substring. If the start offset is beyond the start of the
    /// string, returns an empty string. If the count extends beyond the end of
    /// the string, then end of the string is returned.
    func substring(from start: Int, for length: Int) -> String {

        guard start < self.count else { return "" }
        guard length > 0 else { return "" }

        // If the start offset plus the requested length is longer than
        // the string, trim the length to the remaining characters
        var extractLength = length
        if (start + length > self.count) {
            extractLength = self.count - start
        }

        let indexStartOfText = self.index(self.startIndex, offsetBy: start)
        let indexEndOfText = self.index(self.startIndex, offsetBy: start + extractLength - 1)

        let substring1 = self[indexStartOfText...indexEndOfText]
        return String(substring1)
    }


    /// Extracts a sub-string from an existing string starting at the specified
    /// start character index and for the number of characters. Returns a new
    /// string. The start location and length are passed as an NSRange instance.
    ///
    /// - Parameter nsrange: The range to be extracted from the string.
    ///
    /// - Returns:
    /// Returns the substring. If the start offset is beyond the start of the
    /// string, returns an empty string. If the count extends beyond the end of
    /// the string, then end of the string is returned.
    func substring(with nsrange: NSRange) -> String? {

        let start = nsrange.location
        let length = nsrange.length

        return self.substring(from: start, for: length)
    }

    /// Returns 'count' characters from the start of a string
    ///
    /// - Parameter count: The number of characters to return
    func left(count: Int) -> String {

        guard count > 0 else { return "" }
        guard count <= self.count else { return self }

        let indexEndOfText = self.index(self.startIndex, offsetBy: count - 1)

        // Swift 4
        let substring1 = self[...indexEndOfText]
        return String(substring1)
    }

    /// Returns the characters in a strng from the start location to the end of the string
    ///
    /// - Parameter from: The start position of the string to extract
    ///
    /// If the start position is beyond the end of the string, returns a blank string
    func right(from: Int) -> String {

        guard from <= self.count else { return "" }

        let indexStartOfText = self.index(self.startIndex, offsetBy: from)
        guard indexStartOfText < self.endIndex else { return "" }

        // Swift 4
        let substring1 = self[indexStartOfText...]

        return String(substring1)
    }

    /// Returns the specified number of characters from the end of a string
    ///
    /// - Parameter count: The number of characters to return
    ///
    /// If the count is larger than the string length, returns the entire string
    func right(count: Int) -> String {

        guard count <= self.count else { return self }

        let indexStartOfText = self.index(self.startIndex, offsetBy: self.count - count)
        guard indexStartOfText < self.endIndex else { return "" }

        // Swift 4
        let substring1 = self[indexStartOfText...]

        return String(substring1)
    }

    /// Returns the Character at the specified position in the string
    ///
    /// - Parameter index: The offset of the character
    ///
    /// If the index is beyond the end of the string, then nil is returned.
    func charAt(at index: Int) -> Character! {

        let indexStartOfText = self.index(self.startIndex, offsetBy: index)
        guard indexStartOfText < self.endIndex else { return nil }

        let indexEndOfText = indexStartOfText

        let substring1 = self[indexStartOfText...indexEndOfText]

        if String(substring1.first!) == "\r\n" {
            return "\n"
        }

        return substring1.first
    }

    /// Returns the position of a substring within the string.
    ///
    /// - Parameters:
    ///   - str: The string to be located
    ///   - startPos: An optional position to start the string search
    ///   - caseInsensitive: True of the search is case insensitive, else false
    ///
    func indexOf(str: String, startPos: Int = 0, caseInsensitive: Bool = false) -> Int {

        let testLength = str.count
        let testString = caseInsensitive ? str.lowercased() : str
        let thisString = caseInsensitive ? self.lowercased() : self

        guard self.count - testLength >= startPos else {
            return -1
        }

        for index in startPos ... self.count - testLength {
            if testString == thisString.substring(from: index, for: testLength) {
                return index
            }
        }

        return -1
    }

    /// Returns the position of a character in the string. You can optionally
    /// pass in the start position to start searching at.
    ///
    /// - Parameters:
    ///   - ch: The character to be searched for
    ///   - startPos: Optional start position to seaerch from. Defaults to the first character
    ///
    func indexOf(ch: Character, startPos: Int = 0) -> Int {

        let testChars = Array(self)

        for index in startPos ... testChars.count - 1 {
            if ch == testChars[index] {
                return index
            }
        }

        return -1
    }

    /// Returns the index of the first character in an array of characters
    /// within a string. The first matching character in the array returns the
    /// index.
    ///
    /// - Parameters:
    ///   - ch: An array of characters to test
    ///   - startPos: Optional start position to search from, defaults to the start of the string
    func indexOfAny(ch: [Character], startPos: Int = 0) -> Int {

        let testChars = Array(self)
        guard testChars.count > 0 else {
            return -1
        }
        
        for index in startPos ... testChars.count - 1 {
            let current = testChars[index]
            for chr in ch {
                if (chr == current) {
                    return index
                }
            }
        }

        return -1
    }
}
