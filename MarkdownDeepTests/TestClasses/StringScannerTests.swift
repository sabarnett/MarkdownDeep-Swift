// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest
@testable import MarkdownDeep

class StringScannerTests: XCTestCase {

    func testScanner() {
        let p = StringScanner()

        p.reset("This is a string with something [bracketed]");
        XCTAssertTrue(p.bof);
        XCTAssertFalse(p.eof);
        XCTAssertTrue(p.skipString("This"));
        XCTAssertFalse(p.bof);
        XCTAssertFalse(p.eof);
        XCTAssertFalse(p.skipString("huh?"));
        XCTAssertTrue(p.skipLinespace());
        XCTAssertTrue(p.skipChar("i"));
        XCTAssertTrue(p.skipChar("s"));
        XCTAssertTrue(p.skipWhitespace());
        XCTAssertTrue(p.doesMatchAny(["r", "a", "t"]));
        XCTAssertFalse(p.find("Not here"));
        XCTAssertFalse(p.find("WITH"));
        XCTAssertFalse(p.findI("Not here"));
        XCTAssertTrue(p.findI("WITH"));
        XCTAssertTrue(p.find("["));
        p.skipForward(1);
        p.markPosition()
        XCTAssertTrue(p.find("]"));
        XCTAssertEqual("bracketed", p.extract());
        XCTAssertTrue(p.skipChar("]"));
        XCTAssertTrue(p.eof);
    }
}
