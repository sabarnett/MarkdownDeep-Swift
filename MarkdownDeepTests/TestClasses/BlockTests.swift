// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//
// incorporating BlockProcessorTests from the cs project
//

import XCTest
@testable import MarkdownDeep

class BlockTests: XCTestCase {

    var p: BlockProcessor? = nil;

    override func setUp() {
        p = BlockProcessor(Markdown(), false)
    }

    func testSingleLineParagraph() {
        let b = p!.process("paragraph")

        XCTAssertEqual(1, b.count);
        XCTAssertEqual(BlockType.p, b[0].blockType);
        XCTAssertEqual("paragraph", b[0].content);
    }

    func testMultilineParagraph() {
        let b = p!.process("l1\nl2\n\n")

        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.p, b[0].blockType)
        XCTAssertEqual("l1\nl2", b[0].content)
    }

    func testSetExH1() {
        let b = p!.process("heading\n===\n\n")

        XCTAssertEqual(1, b.count);
        XCTAssertEqual(BlockType.h1, b[0].blockType);
        XCTAssertEqual("heading", b[0].content);
    }

    func testSetExH2() {
        let b = p!.process("heading\n---\n\n")

        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.h2, b[0].blockType)
        XCTAssertEqual("heading", b[0].content)
    }

    func testSetExtHeadingInParagraph() {
        let b = p!.process("p1\nheading\n---\np2\n")
        XCTAssertEqual(3, b.count)

        XCTAssertEqual(BlockType.p, b[0].blockType)
        XCTAssertEqual("p1", b[0].content)

        XCTAssertEqual(BlockType.h2, b[1].blockType)
        XCTAssertEqual("heading", b[1].content)

        XCTAssertEqual(BlockType.p, b[2].blockType)
        XCTAssertEqual("p2", b[2].content)
    }

    func testAtxHeaders() {
        let b = p!.process("#heading#\nparagraph\n")
        XCTAssertEqual(2, b.count)

        XCTAssertEqual(BlockType.h1, b[0].blockType)
        XCTAssertEqual("heading", b[0].content)

        XCTAssertEqual(BlockType.p, b[1].blockType)
        XCTAssertEqual("paragraph", b[1].content)
    }

    func testAtxHeadingInParagraph() {
        let b = p!.process("p1\n## heading ##\np2\n")

        XCTAssertEqual(3, b.count)

        XCTAssertEqual(BlockType.p, b[0].blockType)
        XCTAssertEqual("p1", b[0].content)

        XCTAssertEqual(BlockType.h2, b[1].blockType)
        XCTAssertEqual("heading", b[1].content)

        XCTAssertEqual(BlockType.p, b[2].blockType)
        XCTAssertEqual("p2", b[2].content)
    }

    func testCodeBlock() {
        let b = p!.process("\tcode1\n\t\tcode2\n\tcode3\nparagraph")
        XCTAssertEqual(2, b.count)

        let cb: Block = b[0];
        XCTAssertEqual("code1\n\tcode2\ncode3\n", cb.content)

        XCTAssertEqual(BlockType.p, b[1].blockType)
        XCTAssertEqual("paragraph", b[1].content)
    }

    func testHtmlBlockText() {
        let b = p!.process("<div>\n</div>\n")

        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.html, b[0].blockType)
        XCTAssertEqual("<div>\n</div>\n", b[0].content)
    }

    func testHtmlCommentBlock() {
        let b = p!.process("<!-- this is a\ncomments -->\n")

        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.html, b[0].blockType)
        XCTAssertEqual("<!-- this is a\ncomments -->\n", b[0].content)
    }

    func testHorizontalRules() {
        var b = p!.process("---\n")
        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.hr, b[0].blockType)

        b = p!.process("___\n")
        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.hr, b[0].blockType)

        b = p!.process("***\n")
        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.hr, b[0].blockType)

        b = p!.process(" - - - \n")
        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.hr, b[0].blockType)

        b = p!.process("  _ _ _ \n")
        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.hr, b[0].blockType)

        b = p!.process(" * * * \n")
        XCTAssertEqual(1, b.count)
        XCTAssertEqual(BlockType.hr, b[0].blockType)    }
}
