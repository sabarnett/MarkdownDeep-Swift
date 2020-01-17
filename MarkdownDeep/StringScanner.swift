//
//  MarkdownDeep for SWIFT
//     Copyright (C) 2019 Steven Barnett
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

    // MARK:- Public Interface

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

    // Constructor
    init() {
    }

    // Constructor
    init(_ str: String!) {
        reset(str)
    }

    // Constructor
    init(_ str: String!, _ pos: Int) {
        reset(str, pos)
    }

    // Constructor
    init(_ str: String!, _ pos: Int, _ len: Int) {
        reset(str, pos, len)
    }

    // Reset
    func reset(_ str: String!) {
        reset(str, 0, (str != nil ? str.count : 0))
    }

    // Reset
    func reset(_ str: String!, _ pos: Int) {
        reset(str, pos, (str != nil ? str.count - pos : 0))
    }

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

    // Skip to the end of file
    func skipToEof() {
        pos = end
    }

    // Skip to the end of the current line
    func skipToEol() {
        while pos < end {
            let ch = str!.charAt(at: pos)
            // Fudge. if the returned value is \r\n, we get that back. But that cannot
            // be tested for as a character check. So make it a string and compare
            // the strings
            let st = String(ch!)
            if st == "\r" || st == "\n" ||  st == "\r\n" || st == "\n\r" {
                break
            }
            pos += 1
        }
    }

    // Skip if currently at a line end
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
            } else {
                if ch == "\n" {
                    pos += 1
                    if (pos < end) && (testStr.charAt(at: pos) == "\r") {
                        pos += 1
                    }
                    return true
                }
            }
        }
        return false
    }

    // Skip to the next line
    func skipToNextLine() {
        skipToEol()
        skipEol()
    }

    // Get the character at offset from current position
    //  Or, \0 if out of range
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

    // Skip a number of characters
    func skipForward(_ characters: Int) {
        pos = pos + characters
    }

    // Skip a character if present
    @discardableResult
    func skipChar(_ ch: Character) -> Bool {
        if current == ch {
            skipForward(1)
            return true
        }
        return false
    }

    // Skip a matching string
    @discardableResult
    func skipString(_ str: String!) -> Bool {
        if doesMatch(str) {
            skipForward(str.count)
            return true
        }
        return false
    }

    // Skip a matching string
    @discardableResult
    func skipStringI(_ str: String!) -> Bool {
        if doesMatchI(str) {
            skipForward(str.count)
            return true
        }
        return false
    }

    // Skip any whitespace
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

    func skipEscapableChar(_ ExtraMode: Bool) {
        if (current == "\\") && Utils.isEscapableChar(charAtOffset(1), ExtraMode) {
            skipForward(2)
        } else {
            skipForward(1)
        }
    }

    // Check if a character is space or tab
    func isLineSpace(_ ch: Character) -> Bool {
        return (ch == " ") || (ch == "\t")
    }

    // Skip spaces and tabs
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

    // Does current character match something
    func doesMatch(_ ch: Character) -> Bool {
        return current == ch
    }

    // Does character at offset match a character
    func doesMatch(_ offset: Int, _ ch: Character) -> Bool {
        return charAtOffset(offset) == ch
    }

    // Does current character match any of a range of characters
    func doesMatchAny(_ chars: [String]) -> Bool {
        for i in 0 ... chars.count - 1 {
            if doesMatch(chars[i]) {
                return true
            }
        }
        return false
    }

    // Does current character match any of a range of characters
    func doesMatchAny(_ offset: Int, _ chars: [Character]) -> Bool {
        for testChar in chars {
            if doesMatch(offset, testChar) {
                return true
            }
        }
        return false
    }

    // Does current string position match a string
    func doesMatch(_ str: String!) -> Bool {
        for i in 0 ... str.count - 1 {
            if str!.charAt(at: i) != charAtOffset(i) {
                return false
            }
        }
        return true
    }

    // Does current string position match a string
    func doesMatchI(_ str: String) -> Bool {
        let left = str.lowercased()
        let right = substring(position, str.count).lowercased()
        return left == right
    }

    // Extract a substring
    func substring(_ start: Int) -> String {
        return str.substring(from: start, for: end - start)
    }

    // Extract a substring
    func substring(_ start: Int, _ len: Int) -> String {
        var length = len
        if (start + len) > end {
            length = end - start
        }
        return str.substring(from: start, for: length)
    }

    // Scan forward for a character
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

    // Find any of a range of characters
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

    // Forward scan for a string
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

    // Forward scan for a string (case insensitive)
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

    // Mark current position
    func markPosition() {
        mark = pos
    }

    // Extract string from mark to current position
    func extract() -> String! {
        if mark >= pos {
            return ""
        }
        return str.substring(from: mark, for: pos - mark)
    }

    // Skip an identifier
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

    // Skip a Html entity (eg: &amp;)
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

    // Check if a character marks end of line
    func isLineEnd(_ ch: Character) -> Bool {
        return (ch == "\r") || (ch == "\n") || (ch == "\0")
    }

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
