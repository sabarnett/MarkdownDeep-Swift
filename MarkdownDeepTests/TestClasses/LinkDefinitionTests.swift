// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest
@testable import MarkdownDeep

class LinkDefinitionTests: XCTestCase {

    var r: LinkDefinition?

    override func setUp() {
        r = nil
    }

    func testNoTitle()
    {
        let str: String = "[id]: url.com";
        r = LinkDefinition.parseLinkDefinition(str, false)

        XCTAssertNotNil(r)
        XCTAssertEqual(r!.id, "id")
        XCTAssertEqual(r!.url, "url.com")
        XCTAssertEqual(r!.title, nil)
    }

    func testDoubleQuoteTitle()
    {
        let str: String = "[id]: url.com \"my title\"";
        r = LinkDefinition.parseLinkDefinition(str, false)

        XCTAssertNotNil(r)
        XCTAssertEqual(r!.id, "id")
        XCTAssertEqual(r!.url, "url.com")
        XCTAssertEqual(r!.title, "my title")
    }

    func testSingleQuoteTitle()
    {
        let str: String = "[id]: url.com \'my title\'";
        r = LinkDefinition.parseLinkDefinition(str, false)

        XCTAssertNotNil(r)
        XCTAssertEqual(r!.id, "id")
        XCTAssertEqual(r!.url, "url.com")
        XCTAssertEqual(r!.title, "my title")
    }

    func testParenthesizedTitle()
    {
        let str: String = "[id]: url.com (my title)";
        r = LinkDefinition.parseLinkDefinition(str, false)

        XCTAssertNotNil(r)
        XCTAssertEqual(r!.id, "id")
        XCTAssertEqual(r!.url, "url.com")
        XCTAssertEqual(r!.title, "my title")
    }

    func testAngleBracketedUrl()
    {
        let str: String = "[id]: <url.com> (my title)";
        r = LinkDefinition.parseLinkDefinition(str, false)

        XCTAssertNotNil(r)
        XCTAssertEqual(r!.id, "id")
        XCTAssertEqual(r!.url, "url.com")
        XCTAssertEqual(r!.title, "my title")
    }

    func testMultiLine()
    {
        let str: String = "[id]:\n\t     http://www.site.com \n\t      (my title)";
        r = LinkDefinition.parseLinkDefinition(str, false)

        XCTAssertNotNil(r)
        XCTAssertEqual(r!.id, "id")
        XCTAssertEqual(r!.url, "http://www.site.com")
        XCTAssertEqual(r!.title, "my title")
    }

    func testInvalid()
    {
        XCTAssertNil(LinkDefinition.parseLinkDefinition("[id", false))
        XCTAssertNil(LinkDefinition.parseLinkDefinition("[id]", false))
        XCTAssertNil(LinkDefinition.parseLinkDefinition("[id]:", false))
        XCTAssertNil(LinkDefinition.parseLinkDefinition("[id]: <url", false))
        XCTAssertNil(LinkDefinition.parseLinkDefinition("[id]: <url> \"title", false))
        XCTAssertNil(LinkDefinition.parseLinkDefinition("[id]: <url> \'title", false))
        XCTAssertNil(LinkDefinition.parseLinkDefinition("[id]: <url> (title", false))
        XCTAssertNil(LinkDefinition.parseLinkDefinition("[id]: <url> \"title\" crap", false))
        XCTAssertNil(LinkDefinition.parseLinkDefinition("[id]: <url> crap", false))
    }

}
