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

class Utils {


    /// Check if a character is escapable in markdown
    /// - Parameters:
    ///   - ch: The character to test
    ///   - ExtraMode: Flag: Did the caller specify ExtraMode. If so, we include
    ///     additional characters as escapably characters.
    static func isEscapableChar(_ ch: Character, _ ExtraMode: Bool) -> Bool {
        switch ch {
            case "\\", "`", "*", "_", "{", "}",
                 "[", "]", "(", ")", ">", "#",
                 "+", "-", ".", "!":
                return true

            case ":", "|", "=", "<":
                return ExtraMode

        default:
                return false
        }
    }

    /// Scan a string for a valid identifier.  Identifier must start
    /// with alpha or underscore and can be followed by alpha, digit or underscore.
    /// Updates `pos` to character after the identifier if matched
    ///
    /// - Parameters:
    ///   - str: The string to be scanned
    ///   - pos: The start position to seart scanning from and the next
    ///   position when we exit.
    ///   - identifer: The validated identifier we extracted
    static func parseIdentifier(_ str: String, _ pos: inout Int, _ identifer: inout String) -> Bool {

        if pos >= str.count {
            return false
        }

        //  Must start with a letter or underscore
        var ch = str.charAt(at: pos)!
        if !ch.isLetter && ch != "_" {
            return false
        }
        //  Find the end
        let startpos: Int = pos
        pos += 1

        if (pos < str.count) {
            ch = str.charAt(at: pos)!
            while (pos < str.count - 1) && (ch.isNumber || ch.isLetter || (ch == "_")) {
                pos += 1
                ch = str.charAt(at: pos)!
            }
        }

        //  Return it
        identifer = str.substring(from: startpos, for: pos - startpos)
        return true
    }

    /// Skip over anything that looks like a valid html entity (eg: &amp, &#123, &#nnn) etc...
    ///  Updates `pos` to character after the entity if matched
    ///
    /// - Parameters:
    ///   - str: The string being analysed
    ///   - pos: The current position in the string
    ///   - entity: The entity we found
    static func skipHtmlEntity(_ str: String, _ pos: inout Int, _ entity: inout String) -> Bool {
        if str.charAt(at: pos) != "&" {
            return false
        }

        let savepos: Int = pos
        let len: Int = str.count
        var i: Int = pos + 1

        //  Number entity?
        var bNumber: Bool = false
        var bHex: Bool = false

        if (i < len && str.charAt(at: i) == "#") {
            bNumber = true
            i += 1

            //  Hex identity?
            if (i < len) && ((str.charAt(at: i) == "x") || (str.charAt(at: i) == "X")) {
                bHex = true
                i += 1
            }
        }
        
        //  Parse the content
        let contentpos: Int = i
        while i < len {
            let ch = str.charAt(at: i)!
            if bHex {
                if !(ch.isNumber || ((ch >= "a") && (ch <= "f")) || ((ch >= "A") && (ch <= "F"))) {
                    break
                }
            } else if bNumber {
                if !ch.isNumber {
                    break
                }
            } else if !(ch.isNumber || ch.isLetter) {
                    break
                }

            i += 1
        }

        //  Quit if ran out of string
        if i == len {
            return false
        }

        //  Quit if nothing in the content
        if i == contentpos {
            return false
        }

        //  Quit if didn't find a semicolon
        if str.charAt(at: i) != ";" {
            return false
        }

        //  Looks good...
        pos = i + 1
        entity = str.substring(from: savepos, for: pos - savepos)
        return true
    }

    /// Randomize a string using html entities; This consists of taking plain text
    /// and converting the characters to numeric values. Makes the text difficult to
    /// extract by any page scraing tools.
    /// - Parameters:
    ///   - dest: The buffer the encoded address should be added to
    ///   - str: The input ahhress
    static func htmlRandomize(_ dest: inout String, _ str: String) {
        let rnd = RandomNumberGenerator()

        for ch in str {
            let x = (rnd.next()! % 99 + 1)
            if (x > 90) && (ch != "@") {
                dest.append(ch)
            } else {
                let chValue = UnicodeScalar(String(ch))!.value
                if x > 45 {
                    dest.append("&#")
                    dest.append(String(chValue))
                    dest.append(";")
                } else {
                    dest.append("&#x")
                    dest.append(String(format: "%02x", chValue))
                    dest.append(";")
                }
            }
        }
    }

    /// Acts like HtmlEncode, but don't escape &'s that look like html entities
    /// - Parameters:
    ///   - dest: The buffer to add the results to
    ///   - str: The string to be encoded
    static func smartHtmlEncodeAmpsAndAngles(_ dest: inout String, _ str: String!) {
        guard str != nil else { return }

        var index = 0
        while index < str.count {

            switch str.charAt(at: index) {
                case "&":
                    let start: Int = index
                    var unused: String = ""

                    if skipHtmlEntity(str, &index, &unused) {
                        dest.append(str.substring(from: start, for: index - start))
                        index -= 1
                    } else {
                        dest.append("&amp;")
                    }
                case "<":
                    dest.append("&lt;")
                case ">":
                    dest.append("&gt;")
                case "\"":
                    dest.append("&quot;")
                default:
                    dest.append(str.charAt(at: index))
            }

            index += 1
        }
    }

    /// Acts like HtmlEncode, but only escape &'s that don't look like html entities
    /// - Parameters:
    ///   - dest: The buffer to add the results to
    ///   - str: The string to be encoded
    ///   - startOffset: The offset in the string to encode
    ///   - len: The length of the text to encode
    static func smartHtmlEncodeAmps(_ dest: inout String, _ str: String, _ startOffset: Int, _ len: Int) {

        let end: Int = startOffset + len

        var index = startOffset
        while index < end {

            switch str.charAt(at: index) {
                case "&":
                    let start: Int = index
                    var unused: String = ""

                    if skipHtmlEntity(str, &index, &unused) {
                        dest.append(str.substring(from: start, for: index - start))
                        index -= 1
                    } else {
                        dest.append("&amp;")
                    }
                default:
                    dest.append(str.charAt(at: index))
            }

            index += 1
        }
    }

    /// Check if a url is "safe" (we require urls start with valid protocol)
    ///  Definitely don't allow "javascript:" or any of it's encodings.
    /// - Parameter url: The URL to be tested (String)
    static func isSafeUrl(_ url: String) -> Bool {
        let testUrl = url.lowercased()
        if !testUrl.hasPrefix("http://") && !testUrl.hasPrefix("https://") && !testUrl.hasPrefix("ftp://") {
            return false
        }
        return true
    }

    /// Remove the markdown escapes from a string
    /// - Parameters:
    ///   - str: The string to be un-escaped
    ///   - ExtraMode: Indicator: did the caller specify ExtraMode - affects what is
    ///         considered an escapable character.
    static func unescapeString(_ str: String, _ ExtraMode: Bool) -> String {

        if str.firstIndex(of: "\\") == nil {
            return str
        }

        var b = ""
        var index = 0
        while index < str.count {
            if (str.charAt(at: index) == "\\")
                && ((index + 1) < str.count)
                && Utils.isEscapableChar(str.charAt(at: index + 1), ExtraMode) {
                b.append(str.charAt(at: index + 1))
                index += 1
            } else {
                b.append(str.charAt(at: index))
            }

            index += 1
        }
        return b
    }

    /// Standardise the line end character so line ends will always be a newline
    static func normalizeLineEnds(_ str: String) -> String! {

        let lineends: [Character] = ["\r", "\n"]

        if str.indexOfAny(ch: lineends) < 0 {
            return str
        }

        var sb = ""
        let sp = StringScanner(str)
        while !sp.eof {
            if sp.eol {
                sb.append("\n")
                sp.skipEol()
            } else {
                sb.append(sp.current)
                sp.skipForward(1)
            }
        }
        return sb
    }

    /// Check if a string looks like an email address - this is a quick and
    /// dirty check, not a comprehensive validation. You could replace this
    /// with a regex, but it greatly slows the parsing.
    static func isEmailAddress(_ str: String) -> Bool {

        guard let atPos = str.firstIndex(of: "@") else { return false }
        guard let dotPos = str.lastIndex(of: ".") else { return false }

        if dotPos < atPos {
            return false
        }

        return true
    }

    /// Check if a string looks like a URL - this is a quick and
    /// dirty check, not a comprehensive validation. You could replace this
    /// with a regex, but it greatly slows the parsing.
    static func isWebAddress(_ str: String) -> Bool {
        let testStr = str.lowercased()
        return testStr.hasPrefix("http://")
            || testStr.hasPrefix("https://")
            || testStr.hasPrefix("ftp://")
            || testStr.hasPrefix("file://")
    }

    /// Check if a string is a valid HTML ID identifier
    static func isValidHtmlID(_ str: String!) -> Bool {

        if str == nil || str!.count == 0 {
            return false
        }

        //  Must start with a letter
        let ch = str.first!
        if !ch.isLetter {
            return false
        }
        //  Check the rest
        for ch in str {
            if (ch.isLetter || ch.isNumber)
                || (ch == "_")
                || (ch == "-")
                || (ch == ":")
                || (ch == ".") {
                continue
            }
            return false
        }

        //  OK
        return true
    }

    /// Strip the trailing HTML ID from a header string
    ///  ie:      ## header text ##            {#<idhere>}
    ///             ^start           ^out end              ^end
    ///
    ///  Returns null if no header id
    static func stripHtmlID(_ str: String, _ start: Int, _ end: inout Int) -> String! {

        //  Skip trailing whitespace
        var pos: Int = end - 1
        while (pos >= start) && str.charAt(at: pos).isWhitespace{
            pos -= 1
        }

        //  Skip closing '{'
        if (pos < start) || (str.charAt(at: pos) != "}") {
            return nil
        }

        let endId = pos
        pos -= 1
        //  Find the opening '{'
        while (pos >= start) && (str.charAt(at: pos) != "{") {
            pos -= 1
        }
        //  Check for the #
        if (pos < start) || (str.charAt(at: pos + 1) != "#") {
            return nil
        }

        //  Extract and check the ID
        let startId = pos + 2
        let strID: String! = str.substring(from: startId, for: endId - startId)
        if !isValidHtmlID(strID) {
            return nil
        }

        //  Skip any preceeding whitespace
        while (pos > start)
            && str.charAt(at: pos - 1).isWhitespace {
            pos -= 1
        }

        //  Done!
        end = pos
        return strID
    }

    /// Returns whether the URL starts with "mailto" or a "<protocol>://" prefix
    static func isUrlFullyQualified(_ url: String) -> Bool {

        return url.contains("://") || url.lowercased().hasPrefix("mailto:") 
    }

}
