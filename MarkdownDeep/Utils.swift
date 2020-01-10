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

class Utils {


    // Check if a character is escapable in markdown
    public static func isEscapableChar(_ ch: Character, _ ExtraMode: Bool) -> Bool {
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

    // Extension method. Get the last item in a list (or null if empty)
    public func last<T>(_ list: [T]) -> T! {
        if list.count > 0 {
            return list[list.count - 1]
        } else {
            return nil
        }
    }

    // Extension method. Get the first item in a list (or null if empty)
    public func First<T>(_ list: [T]) -> T! {
        if list.count > 0 {
            return list[0]
        } else {
            return nil
        }
    }

    // Extension method.  Use a list like a stack
    public func push<T>(_ list: inout [T], _ value: T!) {
        list.append(value)
    }

    // Extension method.  Remove last item from a list
    public func pop<T>(_ list: inout [T]) -> T! {
        if list.count == 0 {
            return nil
        } else {
            let val: T! = list[list.count - 1]
            list.remove(at: list.count - 1)
            return val
        }
    }

    // Scan a string for a valid identifier.  Identifier must start with alpha or underscore
    //  and can be followed by alpha, digit or underscore
    //  Updates `pos` to character after the identifier if matched
    public static func parseIdentifier(_ str: String, _ pos: inout Int, _ identifer: inout String) -> Bool {

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

        ch = str.charAt(at: pos)!
        while (pos < str.count) && (ch.isNumber || ch.isLetter || (ch == "_")) {
            pos += 1
            ch = str.charAt(at: pos)!
        }

        //  Return it
        identifer = str.substring(from: startpos, for: pos - startpos)
        return true
    }

    // Skip over anything that looks like a valid html entity (eg: &amp, &#123, &#nnn) etc...
    //  Updates `pos` to character after the entity if matched
    public static func skipHtmlEntity(_ str: String, _ pos: inout Int, _ entity: inout String) -> Bool {
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

    // Randomize a string using html entities;
    public static func htmlRandomize(_ dest: inout String, _ str: String) {
        //  Randomize
        let rnd = RandomNumberGenerator()

        for ch in str {
//            let x = Int.random(in: 0..<100)
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

    // Like HtmlEncode, but don't escape &'s that look like html entities
    public static func smartHtmlEncodeAmpsAndAngles(_ dest: inout String, _ str: String!) {
        if str == nil {
            return
        }

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

    // Like HtmlEncode, but only escape &'s that don't look like html entities
    public static func smartHtmlEncodeAmps(_ dest: inout String, _ str: String, _ startOffset: Int, _ len: Int) {

        let end: Int = startOffset + len

        var index = startOffset
        while index < end {

            switch str.charAt(at: index) {
                case "&":
                    let start: Int = index
                    var unused: String! = nil

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

    // Check if a string is in an array of strings
    public static func isInList(_ str: String, _ list: [String]) -> Bool {
        for t in list {
            if t == str {
                return true
            }
        }
        return false
    }

    // Check if a url is "safe" (we require urls start with valid protocol)
    //  Definitely don't allow "javascript:" or any of it's encodings.
    public static func isSafeUrl(_ url: String) -> Bool {
        if !url.hasPrefix("http://") && !url.hasPrefix("https://") && !url.hasPrefix("ftp://") {
            return false
        }
        return true
    }

    // Remove the markdown escapes from a string
    public static func unescapeString(_ str: String, _ ExtraMode: Bool) -> String {

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

    public static func normalizeLineEnds(_ str: String) -> String! {

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

    // * These two functions IsEmailAddress and IsWebAddress
    //          * are intended as a quick and dirty way to tell if a
    //          * <autolink> url is email, web address or neither.
    //          *
    //          * They are not intended as validating checks.
    //          *
    //          * (use of Regex for more correct test unnecessarily
    //          *  slowed down some test documents by up to 300%.)
    //
    //  Check if a string looks like an email address
    public static func isEmailAddress(_ str: String) -> Bool {

        guard let atPos = str.firstIndex(of: "@") else { return false }
        guard let dotPos = str.lastIndex(of: ".") else { return false }

        if dotPos < atPos {
            return false
        }

        return true
    }

    // Check if a string looks like a url
    public static func isWebAddress(_ str: String) -> Bool {
        return str.hasPrefix("http://")
            || str.hasPrefix("https://")
            || str.hasPrefix("ftp://")
            || str.hasPrefix("file://")
    }

    // Check if a string is a valid HTML ID identifier
    internal static func isValidHtmlID(_ str: String!) -> Bool {

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

    // Strip the trailing HTML ID from a header string
    //  ie:      ## header text ##            {#<idhere>}
    //             ^start           ^out end              ^end
    //
    //  Returns null if no header id
    public static func stripHtmlID(_ str: String, _ start: Int, _ end: inout Int) -> String! {

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

    public static func isUrlFullyQualified(_ url: String) -> Bool {

        return url.contains("://") || url.hasPrefix("Mailto:") 
    }

}
