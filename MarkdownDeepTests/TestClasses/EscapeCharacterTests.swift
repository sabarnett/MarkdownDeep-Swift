// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest
@testable import MarkdownDeep

class EscapeCharacterTests: XCTestCase {

    var f: SpanFormatter? = nil

    override func setUp() {
        f = SpanFormatter(Markdown())
    }

    func testAllEscapeCharacters()
    {
        let testString: String = ###"pre \\ \` \* \_ \{ \} \[ \] \( \) \# \+ \- \. \! post"###

        XCTAssertEqual(#"pre \ ` * _ { } [ ] ( ) # + - . ! post"#,
           f!.format(testString))
    }


    func testSomeNonEscapableCharacters()
    {
        XCTAssertEqual(#"pre \q \% \? post"#,
                       f!.format(#"pre \q \% \? post"#))
    }


    func testBackslashWithTwoDashes()
    {
        XCTAssertEqual(#"backslash with \-- two dashes"#,
                       f!.format(#"backslash with \\-- two dashes"#))
    }


    func testBackslashWithGT()
    {
        XCTAssertEqual(#"backslash with \&gt; greater"#,
                       f!.format(#"backslash with \\> greater"#))
    }


    func testEscapeNotALink()
    {
        XCTAssertEqual(#"\(not a link)"#,
                       f!.format(#"\\\(not a link)"#))
    }


    func testNoEmphasis()
    {
        XCTAssertEqual(#"\*no emphasis*"#,
            f!.format(#"\\\*no emphasis*"#))
    }

}
