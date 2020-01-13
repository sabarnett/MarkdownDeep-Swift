// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//
// Incorporating CodeSpanTests from the cs project
//

import XCTest
@testable import MarkdownDeep

class SpanTests: XCTestCase {

    var f: SpanFormatter? = nil

    override func setUp() {
        f = SpanFormatter(Markdown())
    }

    func testSingleTick() {
        XCTAssertEqual("pre <code>code span</code> post",
                f!.format("pre `code span` post"))
    }

    func testSingleTickWithSpaces() {
        XCTAssertEqual("pre <code>code span</code> post",
                f!.format("pre ` code span ` post"))
    }

    func testMultiTick() {
        XCTAssertEqual("pre <code>code span</code> post",
                f!.format("pre ````code span```` post"))
    }

    func testMultiTickWithEmbeddedTicks() {
        XCTAssertEqual("pre <code>`code span`</code> post",
                f!.format("pre ```` `code span` ```` post"))
    }

    func testContentEncoded() {
        XCTAssertEqual("pre <code>&lt;div&gt;</code> post",
                f!.format("pre ```` <div> ```` post"))
        XCTAssertEqual("pre <code>&amp;amp;</code> post",
                f!.format("pre ```` &amp; ```` post"))
    }
}
