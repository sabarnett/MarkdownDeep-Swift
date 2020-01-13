// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest
@testable import MarkdownDeep

class TableSpecTests: XCTestCase {

    func Parse(_ str: String) -> TableSpec!
    {
        let s = StringScanner(str)
        return TableSpec.parse(s)
    }

    func testSimple()
    {
        let s = Parse("--|--")

        XCTAssertNotNil(s)
        XCTAssertFalse(s!.LeadingBar)
        XCTAssertFalse(s!.TrailingBar)
        XCTAssertEqual(2, s!.Columns.count)
        XCTAssertEqual(ColumnAlignment.NA, s!.Columns[0])
        XCTAssertEqual(ColumnAlignment.NA, s!.Columns[1])
    }

    func testAlignment()
    {
        let s = Parse("--|:--|--:|:--:")

        XCTAssertNotNil(s)
        XCTAssertFalse(s!.LeadingBar)
        XCTAssertFalse(s!.TrailingBar)
        XCTAssertEqual(4, s!.Columns.count)
        XCTAssertEqual(ColumnAlignment.NA, s!.Columns[0])
        XCTAssertEqual(ColumnAlignment.Left, s!.Columns[1])
        XCTAssertEqual(ColumnAlignment.Right, s!.Columns[2])
        XCTAssertEqual(ColumnAlignment.Center, s!.Columns[3])
    }

    func testLeadingTrailingBars()
    {
        let s = Parse("|--|:--|--:|:--:|")

        XCTAssertNotNil(s)
        XCTAssertTrue(s!.LeadingBar)
        XCTAssertTrue(s!.TrailingBar)
        XCTAssertEqual(4, s!.Columns.count)
        XCTAssertEqual(ColumnAlignment.NA, s!.Columns[0])
        XCTAssertEqual(ColumnAlignment.Left, s!.Columns[1])
        XCTAssertEqual(ColumnAlignment.Right, s!.Columns[2])
        XCTAssertEqual(ColumnAlignment.Center, s!.Columns[3])
    }

    func testWhitespace()
    {
        let s = Parse(" | -- | :-- | --: | :--: |  ")

        XCTAssertNotNil(s)
        XCTAssertTrue(s!.LeadingBar)
        XCTAssertTrue(s!.TrailingBar)
        XCTAssertEqual(4, s!.Columns.count)
        XCTAssertEqual(ColumnAlignment.NA, s!.Columns[0])
        XCTAssertEqual(ColumnAlignment.Left, s!.Columns[1])
        XCTAssertEqual(ColumnAlignment.Right, s!.Columns[2])
        XCTAssertEqual(ColumnAlignment.Center, s!.Columns[3])
    }
}
