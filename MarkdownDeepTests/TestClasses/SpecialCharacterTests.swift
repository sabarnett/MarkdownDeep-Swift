// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest
@testable import MarkdownDeep

class SpecialCharacterTests: XCTestCase {

    var f: SpanFormatter?

    override func setUp() {
        f = SpanFormatter(Markdown())
    }

    func testSimpleTag()
    {
        XCTAssertEqual(f!.format("pre <a> post"), "pre <a> post")
    }

    func testTagWithAttributes()
    {
        XCTAssertEqual(f!.format("pre <a href=\"somewhere.html\" target=\"_blank\">link</a> post"), "pre <a href=\"somewhere.html\" target=\"_blank\">link</a> post")
    }

    func testNotATag()
    {
        XCTAssertEqual("pre a &lt; b post",
                f!.format("pre a < b post"))
    }

    func testNotATag2()
    {
        XCTAssertEqual("pre a&lt;b post",
                f!.format("pre a<b post"))
    }

    func testAmpersandsInUrls()
    {
        XCTAssertEqual("pre <a href=\"somewhere.html?arg1=a&amp;arg2=b\" target=\"_blank\">link</a> post",
                f!.format("pre <a href=\"somewhere.html?arg1=a&arg2=b\" target=\"_blank\">link</a> post"))
    }

    func testAmpersandsInParagraphs()
    {
        XCTAssertEqual("pre this &amp; that post",
                f!.format("pre this & that post"))
    }

    func testHtmlEntities()
    {
        XCTAssertEqual("pre &amp; post",
                f!.format("pre &amp; post"))
        XCTAssertEqual("pre &#123; post",
                f!.format("pre &#123; post"))
        XCTAssertEqual("pre &#x1aF; post",
                f!.format("pre &#x1aF; post"))
    }

    func testEscapeChars()
    {
        XCTAssertEqual(##"\ ` * _ { } [ ] ( ) # + - . ! &gt;"##,
                       f!.format(##"\\ \` \* \_ \{ \} \[ \] \( \) \# \+ \- \. \! \>"##))
    }

}
