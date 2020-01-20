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

class StringScanner {
    var str: String!
    var start: Int = 0
    var pos: Int = 0
    var end: Int = 0
    var mark: Int = 0

    // MARK:- Computed Properties

    var input: String! {
        get {
            return str
        }
    }

    var current: Character {
        get {
            if (pos < start) || (pos >= end) || str == nil {
                return "\0"
            } else {
                return str!.charAt(at: pos)
            }
        }
    }

    var position: Int {
        get { return pos }
        set { pos = newValue }
    }

    var remainder: String! {
        get { return substring(position) }
    }

    var eof: Bool {
        get {
            return pos >= end
        }
    }

    var eol: Bool {
        get {
            return isLineEnd(current)
        }
    }

    var bof: Bool {
        get {
            return pos == start
        }
    }

    // MARK:- Initialisers

    init() { }

    init(_ str: String!) { reset(str) }

    init(_ str: String!, _ pos: Int) { reset(str, pos) }

    init(_ str: String!, _ pos: Int, _ len: Int) { reset(str, pos, len) }

    func reset(_ str: String!) { reset(str, 0, (str != nil ? str.count : 0)) }

    func reset(_ str: String!, _ pos: Int) { reset(str, pos, (str != nil ? str.count - pos : 0)) }

    // Reset
    func reset(_ str: String!, _ pos: Int, _ len: Int) {
        var resetStr = str
        var resetLen = len
        var resetPos = pos

        if resetStr == nil { resetStr = "" }
        if resetLen < 0 { resetLen = 0 }
        if resetPos < 0 { resetPos = 0 }
        if resetPos > resetStr!.count { resetPos = resetStr!.count }

        self.str = resetStr!
        self.start = resetPos
        self.pos = resetPos
        self.end = resetPos + resetLen

        if end > resetStr!.count {
            end = resetStr!.count
        }
    }

    // MARK:- Helper methods

    /// Skip to the end of the file
    func skipToEof() {
        pos = end
    }

    /// Skip to the end of the current line
    func skipToEol() {
        while pos < end {
            let ch = str!.charAt(at: pos)
            if ch  == "\r" || ch == "\n" {
                break
            }
            pos += 1
        }
    }

    /// Skip if currently at a line end
    @discardableResult
    func skipEol() -> Bool {
        let testStr = str!

        if pos < end {
            let ch = testStr.charAt(at: pos)
            if ch == "\r" {
                pos += 1
                if (pos < end) && (testStr.charAt(at: pos) == "\n") {
                    pos += 1
                }
                return true
            } else if ch == "\n" {
                pos += 1
                if (pos < end) && (testStr.charAt(at: pos) == "\r") {
                    pos += 1
                }
                return true
            }
        }
        return false
    }

    /// Skip to the next line
    func skipToNextLine() {
        skipToEol()
        skipEol()
    }

    /// Get the character at offset from current position or, \0 if out of range
    ///
    /// - Parameter offset: position of the character in the string to retrieve
    func charAtOffset(_ offset: Int) -> Character {
        let index: Int = pos + offset
        if index < start {
            return "\0"
        }
        if index >= end {
            return "\0"
        }
        return str!.charAt(at: index)
    }

    /// Skip a number of characters
    ///
    /// - Parameter characters: The numbe of characters to skip
    func skipForward(_ characters: Int) {
        pos = pos + characters
    }

    /// Skip a character if present
    ///
    /// - Parameter ch: Character to skip
    @discardableResult
    func skipChar(_ ch: Character) -> Bool {
        if current == ch {
            skipForward(1)
            return true
        }
        return false
    }

    /// Skip a matching string - test is case sensitive
    ///
    /// - Parameter str: String to skip
    @discardableResult
    func skipString(_ str: String!) -> Bool {
        if doesMatch(str) {
            skipForward(str.count)
            return true
        }
        return false
    }

    /// Skip a matching string - test is case insensitive
    ///
    /// - Parameter str: String to skip
    @discardableResult
    func skipStringI(_ str: String!) -> Bool {
        if doesMatchI(str) {
            skipForward(str.count)
            return true
        }
        return false
    }

    /// Skip any whitespace
    @discardableResult
    func skipWhitespace() -> Bool {

        if !current.isWhitespace {
            return false
        }

        skipForward(1)
        while current.isWhitespace {
            skipForward(1)
        }

        return true
    }

    /// Skips any escapable characters
    ///
    /// - Parameter ExtraMode: Determines whether we want to include extra characters
    func skipEscapableChar(_ ExtraMode: Bool) {
        if (current == "\\") && Utils.isEscapableChar(charAtOffset(1), ExtraMode) {
            skipForward(2)
        } else {
            skipForward(1)
        }
    }

    /// Check if a character is space or tab
    ///
    /// - Parameter ch: The character to test
    func isLineSpace(_ ch: Character) -> Bool {
        return (ch == " ") || (ch == "\t")
    }

    /// Skip spaces and tabs
    @discardableResult
    func skipLinespace() -> Bool {
        if !isLineSpace(current) {
            return false
        }

        skipForward(1)
        while isLineSpace(current) {
            skipForward(1)
        }

        return true
    }

    /// Does current character match something
    ///
    /// - Parameter ch: Tghe character to test against
    func doesMatch(_ ch: Character) -> Bool {
        return current == ch
    }

    /// Does character at offset match a character
    ///
    /// - Parameters:
    ///   - offset: Te offset into the string to test
    ///   - ch: The character to test against
    func doesMatch(_ offset: Int, _ ch: Character) -> Bool {
        return charAtOffset(offset) == ch
    }

    /// Does current character match any of a range of characters
    ///
    /// - Parameter chars: An array of letters to test against
    func doesMatchAny(_ chars: [String]) -> Bool {
        for ch in chars {
            if doesMatch(ch) {
                return true
            }
        }
        return false
    }

    /// Does current character match any of a range of characters
    ///
    /// - Parameters:
    ///   - offset: The offset in the string to test
    ///   - chars: Array of characters to test against
    func doesMatchAny(_ offset: Int, _ chars: [Character]) -> Bool {
        for testChar in chars {
            if doesMatch(offset, testChar) {
                return true
            }
        }
        return false
    }

    /// Does current string position match a string
    ///
    /// - Parameter str: The string to test for
    func doesMatch(_ str: String!) -> Bool {
        for i in 0 ... str.count - 1 {
            if str!.charAt(at: i) != charAtOffset(i) {
                return false
            }
        }
        return true
    }

    /// Does current string position match a string - test is case insensitive
    ///
    /// - Parameter str: String to test for
    func doesMatchI(_ str: String) -> Bool {
        let left = str.lowercased()
        let right = substring(position, str.count).lowercased()
        return left == right
    }

    /// Extract a substring
    ///
    /// - Parameter start: Start position of string to extract
    func substring(_ start: Int) -> String {
        return str.substring(from: start, for: end - start)
    }

    /// Extract a substring
    ///
    /// - Parameters:
    ///   - start: The start position of the string to extract
    ///   - len: The number of characters to extract
    func substring(_ start: Int, _ len: Int) -> String {
        var length = len
        if (start + len) > end {
            length = end - start
        }
        return str.substring(from: start, for: length)
    }

    /// Scan forward for a character
    ///
    /// - Parameter ch: The character to find
    func find(_ ch: Character) -> Bool {
        if pos >= end {
            return false
        }

        //  Find it
        let index: Int = str.indexOf(ch: ch, startPos: pos)
        if (index < 0) || (index >= end) {
            return false
        }
        //  Store new position
        pos = index
        return true
    }

    /// Find the first occurence of any of a range of characters
    ///
    /// - Parameter chars: The list of characters to find
    func findAny(_ chars: [Character]) -> Bool {
        if pos >= end {
            return false
        }
        //  Find it
        let index: Int = str.indexOfAny(ch: chars, startPos: pos)
        if (index < 0) || (index >= end) {
            return false
        }

        //  Store new position
        pos = index
        return true
    }

    /// Forward scan for a string
    ///
    /// - Parameter find: The string to find
    func find(_ find: String) -> Bool {
        if pos >= end {
            return false
        }

        let index: Int = str.indexOf(str: find, startPos: pos)
        if (index < 0) || (index > (end - find.count)) {
            return false
        }

        pos = index
        return true
    }

    /// Forward scan for a string (case insensitive)
    ///
    /// - Parameter find: The string to find
    func findI(_ find: String) -> Bool {
        if pos >= end {
            return false
        }
        let index: Int = str.indexOf(str: find, startPos: pos, caseInsensitive: true)
        if (index < 0) || (index >= (end - find.count)) {
            return false
        }
        pos = index
        return true
    }

    /// Mark current position
    func markPosition() {
        mark = pos
    }

    /// Extract string from mark to current position
    func extract() -> String! {
        if mark >= pos {
            return ""
        }
        return str.substring(from: mark, for: pos - mark)
    }

    /// Skip an identifier
    ///
    /// - Parameter identifier: The identifier (id) to skip
    func skipIdentifier(_ identifier: inout String!) -> Bool {
        let savepos: Int = position

        if !Utils.parseIdentifier(self.str, &(pos), &(identifier)) {
            return false
        }

        if pos >= end {
            pos = savepos
            return false
        }
        return true
    }

    /// Skip over a footnote ID
    ///
    /// - Parameter id: The Id to skip
    func skipFootnoteID(_ id: inout String!) -> Bool {
        let savepos: Int = position
        skipLinespace()
        markPosition()

        while true {
            let ch = current
            if (ch.isNumber || ch.isLetter) || (ch == "-") || (ch == "_") || (ch == ":") || (ch == ".") || (ch == " ") {
                skipForward(1)
            } else {
                break
            }
        }

        if position > mark {
            id = extract()?.trimWhitespace()
            if !String.isNullOrEmpty(id) {
                skipLinespace()
                return true
            }
        }
        position = savepos
        id = nil
        return false
    }

    /// Skip a Html entity (eg: &amp;)
    ///
    /// - Parameter entity: The entity to be skipped
    func skipHtmlEntity(_ entity: inout String!) -> Bool {
        let savepos: Int = position
        entity = ""                 // TEST FIX 01

        if !Utils.skipHtmlEntity(self.str, &(pos), &(entity)) {
            return false
        }
        if pos > end {
            pos = savepos
            return false
        }
        return true
    }

    /// Check if a character marks the end of a line
    ///
    /// - Parameter ch: The character to test
    func isLineEnd(_ ch: Character) -> Bool {
        return (ch == "\r") || (ch == "\n") || (ch == "\0")
    }

    /// Test whether a character is valid in a URL
    ///
    /// - Parameter ch: The character to test
    func isUrlChar(_ ch: String) -> Bool {
        switch ch {
            case "+", "&", "@", "#", "/", "%",
                "?", "=", "~", "_", "|", "[",
                "]", "(", ")", "!", ":", ",",
                ".", ";":
                return true
            default:
                let testChar = ch.first
                return testChar!.isLetter || testChar!.isNumber
        }
    }
}
