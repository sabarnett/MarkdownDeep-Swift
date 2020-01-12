// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest
@testable import MarkdownDeep

class HtmlTagTests: XCTestCase {

    var m_pos: Int = 0

    override func setUp() {
        m_pos = 0
    }

    func testUnquoted()
    {
        let str: String = #"<div x=1 y=2>"#;
        let tag = HtmlTag.parse(str: str, pos: &m_pos)!

        XCTAssertEqual(tag.name, "div")
        XCTAssertEqual(tag.closing, false)
        XCTAssertEqual(tag.closed, false)
        XCTAssertEqual(tag.attributes.count, 2)
        XCTAssertEqual(tag.attribute(key: "x"), "1")
        XCTAssertEqual(tag.attribute(key: "y"), "2")
        XCTAssertEqual(m_pos, str.count)

    }


    func testQuoted()
    {
        let str: String = "<div x=\"1\" y=\"2\">"
        let tag = HtmlTag.parse(str: str, pos: &m_pos)!

        XCTAssertEqual(tag.name, "div")
        XCTAssertEqual(tag.closing, false)
        XCTAssertEqual(tag.closed, false)
        XCTAssertEqual(tag.attributes.count, 2)
        XCTAssertEqual(tag.attribute(key: "x"), "1")
        XCTAssertEqual(tag.attribute(key: "y"), "2")
        XCTAssertEqual(m_pos, str.count)

    }


    func testEmpty()
    {
        let str: String = "<div>"
        let tag = HtmlTag.parse(str: str, pos: &m_pos)!

        XCTAssertEqual(tag.name, "div")
        XCTAssertEqual(tag.closing, false)
        XCTAssertEqual(tag.closed, false)
        XCTAssertEqual(tag.attributes.count, 0)
        XCTAssertEqual(m_pos, str.count)

    }


    func testClosed()
    {
        let str: String = "<div/>"
        let tag = HtmlTag.parse(str: str, pos: &m_pos)!

        XCTAssertEqual(tag.name, "div")
        XCTAssertEqual(tag.closing, false)
        XCTAssertEqual(tag.closed, true)
        XCTAssertEqual(tag.attributes.count, 0)
        XCTAssertEqual(m_pos, str.count)

    }


    func testClosedWithAttribs()
    {
        let str: String = "<div x=1 y=2/>"
        let tag = HtmlTag.parse(str: str, pos: &m_pos)!

        XCTAssertEqual(tag.name, "div")
        XCTAssertEqual(tag.closing, false)
        XCTAssertEqual(tag.closed, true)
        XCTAssertEqual(tag.attributes.count, 2)
        XCTAssertEqual(tag.attribute(key: "x"), "1")
        XCTAssertEqual(tag.attribute(key: "y"), "2")
        XCTAssertEqual(m_pos, str.count)

    }


    func testClosing()
    {
        let str: String = "</div>"
        let tag = HtmlTag.parse(str: str, pos: &m_pos)!

        XCTAssertEqual(tag.name, "div")
        XCTAssertEqual(tag.closing, true)
        XCTAssertEqual(tag.closed, false)
        XCTAssertEqual(tag.attributes.count, 0)
        XCTAssertEqual(m_pos, str.count)

    }


    func testComment()
    {
        let str: String = "<!-- comment -->"
        let tag = HtmlTag.parse(str: str, pos: &m_pos)!

        XCTAssertEqual(tag.name, "!")
        XCTAssertEqual(tag.closing, false)
        XCTAssertEqual(tag.closed, true)
        XCTAssertEqual(tag.attributes.count, 1)
        XCTAssertEqual(tag.attribute(key: "content"), " comment ")
        XCTAssertEqual(m_pos, str.count)
    }


    func testNonValuedAttribute()
    {
        let str: String = "<iframe y=\"2\" allowfullscreen x=\"1\" foo>"
        let tag = HtmlTag.parse(str: str, pos: &m_pos)!

        XCTAssertEqual(tag.name, "iframe")
        XCTAssertEqual(tag.closing, false)
        XCTAssertEqual(tag.closed, false)
        XCTAssertEqual(tag.attributes.count, 4)
        XCTAssertEqual(tag.attribute(key: "allowfullscreen"), "")
        XCTAssertEqual(tag.attribute(key: "foo"), "")
        XCTAssertEqual(tag.attribute(key: "y"), "2")
        XCTAssertEqual(tag.attribute(key: "x"), "1")
        XCTAssertEqual(m_pos, str.count)

    }

}
