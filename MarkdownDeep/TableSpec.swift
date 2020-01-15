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

internal class TableSpec {
    public var LeadingBar: Bool = false
    public var TrailingBar: Bool = false
    public var Columns: [ColumnAlignment] = []
    public var Headers: [String] = []
    public var Rows: [[String]] = []

    public func parseRow(_ p: StringScanner) -> [String]! {
        p.skipLinespace()
        if p.eol {
            return nil
        }

        //  Blank line ends the table
        var bAnyBars: Bool = LeadingBar
        if LeadingBar && !p.skipChar("|") {
            return nil
        }
        //  Create the row
        var row = [String]()
        //  Parse all columns except the last
        while !p.eol {
            //  Find the next vertical bar
            p.markPosition()

            while !p.eol && (p.current != "|") {
                p.skipEscapableChar(true)
            }

            row.append(p.extract().trimWhitespace())
            let bSkip = p.skipChar("|")
            bAnyBars = bAnyBars || bSkip
        }

        //  Require at least one bar to continue the table
        if !bAnyBars {
            return nil
        }

        //  Add missing columns
        while row.count < Columns.count {
            row.append("&nbsp;")
        }

        p.skipEol()
        return row
    }

    internal func renderRow(_ m: Markdown, _ b: inout String, _ row: [String], _ type: String) {
        for i in 0 ..< row.count {
            b.append("\t<")
            b.append(type)
            if i < Columns.count {
                switch Columns[i] {
                    case ColumnAlignment.Left:
                        b.append(" align=\"left\"")
                    case ColumnAlignment.Right:
                        b.append(" align=\"right\"")
                    case ColumnAlignment.Center:
                        b.append(" align=\"center\"")
                default:
                        break;
                }
            }
            b.append(">")
            m.getSpanFormatter.format(&b, row[i])
            b.append("</")
            b.append(type)
            b.append(">\n")
        }
    }

    public func render(_ m: Markdown!, _ b: inout String) {
        b.append("<table>\n")

        if Headers.count > 0 {
            b.append("<thead>\n<tr>\n")
            renderRow(m, &b, Headers, "th")
            b.append("</tr>\n</thead>\n")
        }

        b.append("<tbody>\n")
        for row in Rows {
            b.append("<tr>\n")
            renderRow(m, &b, row, "td")
            b.append("</tr>\n")
        }

        b.append("</tbody>\n")
        b.append("</table>\n")
    }

    public static func parse(_ p: StringScanner!) -> TableSpec! {
        //  Leading line space allowed
        p.skipLinespace()
        //  Quick check for typical case
        if (p.current != "|") && (p.current != ":") && (p.current != "-") {
            return nil
        }
        //  Don't create the spec until it at least looks like one
        var spec: TableSpec! = nil
        //  Leading bar, looks like a table spec
        if p.skipChar("|") {
            spec = TableSpec()
            spec.LeadingBar = true
        }
        //  Process all columns
        while true {
            //  Parse column spec
            p.skipLinespace()
            //  Must have something in the spec
            if p.current == "|" {
                return nil
            }

            let alignLeft: Bool = p.skipChar(":")
            while p.current == "-" {
                p.skipForward(1)
            }

            let alignRight: Bool = p.skipChar(":")
            p.skipLinespace()

            //  Work out column alignment
            var col: ColumnAlignment! = ColumnAlignment.NA
            if alignLeft && alignRight {
                col = ColumnAlignment.Center
            } else {
                if alignLeft {
                    col = ColumnAlignment.Left
                } else {
                    if alignRight {
                        col = ColumnAlignment.Right
                    }
                }
            }
            if p.eol {
                //  Not a spec?
                if spec == nil {
                    return nil
                }
                //  Add the final spec?
                spec.Columns.append(col)
                return spec
            }
            //  We expect a vertical bar
            if !p.skipChar("|") {
                return nil
            }
            //  Create the table spec
            if spec == nil {
                spec = TableSpec()
            }
            //  Add the column
            spec.Columns.append(col)
            //  Check for trailing vertical bar
            p.skipLinespace()
            if p.eol {
                spec.TrailingBar = true
                return spec
            }
            //  Next column
        }
    }
}
