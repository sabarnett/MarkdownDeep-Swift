// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest
@testable import MarkdownDeep

class AutoLinkTests: XCTestCase {

    var s: SpanFormatter?

    override func setUp() {
        let m = Markdown()
        s = SpanFormatter(m)
    }

    func testhttp()
    {
        XCTAssertEqual("pre <a href=\"http://url.com\">http://url.com</a> post",
                s!.format("pre <http://url.com> post"))
    }

    func testhttps()
    {
        XCTAssertEqual("pre <a href=\"https://url.com\">https://url.com</a> post",
                s!.format("pre <https://url.com> post"))
    }

    func testftp()
    {
        XCTAssertEqual("pre <a href=\"ftp://url.com\">ftp://url.com</a> post",
                s!.format("pre <ftp://url.com> post"))
    }
}
