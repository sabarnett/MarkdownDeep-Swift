// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import Foundation

class TestDefinition {

    init(testFileName: String) {
        let bundle: Bundle = Bundle(for: type(of: self))

        testName = testFileName

        let testPath = bundle.path(forResource: testFileName, ofType: "txt")!
        self.testString = try! String(contentsOfFile: testPath)

        let resultPath = bundle.path(forResource: testFileName, ofType: "html")!
        self.resultString = try! String(contentsOfFile: resultPath)
    }

    public var testName = ""
    public var testString = ""
    public var resultString = ""
}
