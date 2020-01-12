// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest
@testable import MarkdownDeep

class LinkAndImgTests: XCTestCase {

    var s: SpanFormatter? = nil

    override func setUp() {
        let m = Markdown()

        m.AddLinkDefinition(LinkDefinition("link1", "url.com", "title"))
        m.AddLinkDefinition(LinkDefinition("link2", "url.com"))
        m.AddLinkDefinition(LinkDefinition("img1", "url.com/image.png", "title"))
        m.AddLinkDefinition(LinkDefinition("img2", "url.com/image.png"))

        s = SpanFormatter(m)
    }

    func testReferenceLinkWithTitle()
    {
        XCTAssertEqual("pre <a href=\"url.com\" title=\"title\">link text</a> post",
                s!.format("pre [link text][link1] post"))
    }


    func testReferenceLinkIdsAreCaseInsensitive()
    {
        let testString = "pre <a href=\"url.com\" title=\"title\">link text</a> post"
        let resultString = s!.format("pre [link text][LINK1] post")

        print("String to test")
        print(testString)
        print("Result returned")
        print(resultString)

        XCTAssertEqual(testString, resultString)
    }


    func testImplicitReferenceLinkWithoutTitle()
    {
        XCTAssertEqual("pre <a href=\"url.com\">link2</a> post",
                s!.format("pre [link2] post"))
        XCTAssertEqual("pre <a href=\"url.com\">link2</a> post",
                s!.format("pre [link2][] post"))
    }


    func testImplicitReferenceLinkWithTitle()
    {
        XCTAssertEqual("pre <a href=\"url.com\" title=\"title\">link1</a> post",
                s!.format("pre [link1] post"))
        XCTAssertEqual("pre <a href=\"url.com\" title=\"title\">link1</a> post",
                s!.format("pre [link1][] post"))
    }


    func testReferenceLinkWithoutTitle()
    {
        XCTAssertEqual("pre <a href=\"url.com\">link text</a> post",
                s!.format("pre [link text][link2] post"))
    }


    func testMissingReferenceLink()
    {
        XCTAssertEqual("pre [link text][missing] post",
                s!.format("pre [link text][missing] post"))
    }


    func testInlineLinkWithTitle()
    {
        XCTAssertEqual("pre <a href=\"url.com\" title=\"title\">link text</a> post",
                s!.format("pre [link text](url.com \"title\") post"))
    }


    func testInlineLinkWithoutTitle()
    {
        XCTAssertEqual("pre <a href=\"url.com\">link text</a> post",
                s!.format("pre [link text](url.com) post"))
    }


    func testBoundaries()
    {
        XCTAssertEqual("<a href=\"url.com\">link text</a>",
                s!.format("[link text](url.com)"))
        XCTAssertEqual("<a href=\"url.com\" title=\"title\">link text</a>",
                s!.format("[link text][link1]"))
    }



    func testReferenceImgWithTitle()
    {
        XCTAssertEqual("pre <img src=\"url.com/image.png\" alt=\"alt text\" title=\"title\" /> post",
                s!.format("pre ![alt text][img1] post"))
    }


    func testImplicitReferenceImgWithoutTitle()
    {
        XCTAssertEqual("pre <img src=\"url.com/image.png\" alt=\"img2\" /> post",
                s!.format("pre ![img2] post"))
        XCTAssertEqual("pre <img src=\"url.com/image.png\" alt=\"img2\" /> post",
                s!.format("pre ![img2][] post"))
    }


    func testImplicitReferenceImgWithTitle()
    {
        XCTAssertEqual("pre <img src=\"url.com/image.png\" alt=\"img1\" title=\"title\" /> post",
                s!.format("pre ![img1] post"))
        XCTAssertEqual("pre <img src=\"url.com/image.png\" alt=\"img1\" title=\"title\" /> post",
                s!.format("pre ![img1][] post"))
    }


    func testReferenceImgWithoutTitle()
    {
        XCTAssertEqual("pre <img src=\"url.com/image.png\" alt=\"alt text\" /> post",
                s!.format("pre ![alt text][img2] post"))
    }


    func testMissingReferenceImg()
    {
        XCTAssertEqual("pre ![alt text][missing] post",
                s!.format("pre ![alt text][missing] post"))
    }


    func testInlineImgWithTitle()
    {
        XCTAssertEqual("pre <img src=\"url.com/image.png\" alt=\"alt text\" title=\"title\" /> post",
                s!.format("pre ![alt text](url.com/image.png \"title\") post"))
    }


    func testInlineImgWithoutTitle()
    {
        XCTAssertEqual("pre <img src=\"url.com/image.png\" alt=\"alt text\" /> post",
                s!.format("pre ![alt text](url.com/image.png) post"))
    }



    func testImageLink()
    {
        XCTAssertEqual("pre <a href=\"url.com\"><img src=\"url.com/image.png\" alt=\"alt text\" /></a> post",
                s!.format("pre [![alt text](url.com/image.png)](url.com) post"))
    }

}
