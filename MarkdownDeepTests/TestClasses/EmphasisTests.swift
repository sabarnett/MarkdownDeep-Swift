// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest
@testable import MarkdownDeep

class EmphasisTests: XCTestCase {

    var f: SpanFormatter? = nil;

    override func setUp() {
        f = SpanFormatter(Markdown())
    }

    func testPlainText() {
        XCTAssertEqual("This is plain text",
                f!.format("This is plain text"))
    }

    func testEmSimple() {
        XCTAssertEqual("This is <em>em</em> text",
                f!.format("This is *em* text"))
        XCTAssertEqual("This is <em>em</em> text",
                f!.format("This is _em_ text"))
    }

    func testStrongSimple() {
        XCTAssertEqual("This is <strong>strong</strong> text",
                f!.format("This is **strong** text"))
        XCTAssertEqual("This is <strong>strong</strong> text",
                f!.format("This is __strong__ text"))
    }

    func testEmStrongLeadTail() {
        XCTAssertEqual("<strong>strong</strong>",
                f!.format("__strong__"))
        XCTAssertEqual("<strong>strong</strong>",
                f!.format("**strong**"))
        XCTAssertEqual("<em>em</em>",
                f!.format("_em_"))
        XCTAssertEqual("<em>em</em>",
                f!.format("*em*"))
    }

    func testStrongEm() {
        XCTAssertEqual("<strong><em>strongem</em></strong>",
                f!.format("***strongem***"))
        XCTAssertEqual("<strong><em>strongem</em></strong>",
                f!.format("___strongem___"))
    }

    func testNoStrongEmIfSpaces() {
        XCTAssertEqual("pre * notem *",
                f!.format("pre * notem *"))
        XCTAssertEqual("pre ** notstrong **",
                f!.format("pre ** notstrong **"))
        XCTAssertEqual("pre *Apples *Bananas *Oranges",
                f!.format("pre *Apples *Bananas *Oranges"))
    }

    func testEmInWord() {
        XCTAssertEqual("un<em>frigging</em>believable",
                f!.format("un*frigging*believable"))
    }

    func testStrongInWord() {
        XCTAssertEqual("un<strong>frigging</strong>believable",
                f!.format("un**frigging**believable"))
    }

    func testCombined1() {
        XCTAssertEqual("<strong><em>test test</em></strong>",
                f!.format("***test test***"))
    }

    func testCombined2() {
        XCTAssertEqual("<strong><em>test test</em></strong>",
                f!.format("___test test___"))
    }

    func testCombined3() {
        XCTAssertEqual("<em>test <strong>test</strong></em>",
                f!.format("*test **test***"))
    }

    func testCombined4() {
        XCTAssertEqual("<strong>test <em>test</em></strong>",
                f!.format("**test *test***"))
    }

    func testCombined5() {
        XCTAssertEqual("<strong><em>test</em> test</strong>",
                f!.format("***test* test**"))
    }

    func testCombined6() {
        XCTAssertEqual("<em><strong>test</strong> test</em>",
                f!.format("***test** test*"))
    }

    func testCombined7() {
        XCTAssertEqual("<strong><em>test</em> test</strong>",
                f!.format("***test* test**"))
    }

    func testCombined8() {
        XCTAssertEqual("<strong>test <em>test</em></strong>",
                f!.format("**test *test***"))
    }

    func testCombined9() {
        XCTAssertEqual("<em>test <strong>test</strong></em>",
                f!.format("*test **test***"))
    }

    func testCombined10() {
        XCTAssertEqual("<em>test <strong>test</strong></em>",
                f!.format("_test __test___"))
    }

    func testCombined11() {
        XCTAssertEqual("<strong>test <em>test</em></strong>",
                f!.format("__test _test___"))
    }

    func testCombined12() {
        XCTAssertEqual("<strong><em>test</em> test</strong>",
                f!.format("___test_ test__"))
    }

    func testCombined13() {
        XCTAssertEqual("<em><strong>test</strong> test</em>",
                f!.format("___test__ test_"))
    }

    func testCombined14() {
        XCTAssertEqual("<strong><em>test</em> test</strong>",
                f!.format("___test_ test__"))
    }

    func testCombined15() {
        XCTAssertEqual("<strong>test <em>test</em></strong>",
                f!.format("__test _test___"))
    }

    func testCombined16() {
        XCTAssertEqual("<em>test <strong>test</strong></em>",
                f!.format("_test __test___"))
    }

    func testCombined17() {
        let md = Markdown()
        md.extraMode = true

        let fExtra = SpanFormatter(md)
        XCTAssertEqual("<strong>Bold</strong> <em>Italic</em>",
                fExtra.format("__Bold__ _Italic_"))

    }

    func testCombined18() {
        let md = Markdown()
        md.extraMode = true

        let fExtra = SpanFormatter(md)
        XCTAssertEqual("<em>Emphasis</em>, trailing",
                fExtra.format("_Emphasis_, trailing"))

    }

}
