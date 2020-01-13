// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest

class SafeModeTestsFromResources: XCTestCase {

    func testBasicSafeMode() {
        TestHelper().runTest(testFileName: "Basic(SafeMode)", showDebugInfo: true)
    }
}
