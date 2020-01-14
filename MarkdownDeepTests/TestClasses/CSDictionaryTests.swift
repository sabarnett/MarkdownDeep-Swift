// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import XCTest
@testable import MarkdownDeep

class TestItems {
    var itemValue1: String = "Item Value 1"
    var itemValue2: String = "Item Value 2"
    var itemNumber1: Int = 1
    var itemNumber2: Int = 2
}

class CSDictionaryTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    func testCanCreateEmptyDictionary() {

        let testDictionary = CSDictionary<TestItems>()
        XCTAssertEqual(testDictionary.count, 0)
        
    }

    func testCanAddSingleItem() {
        var testDictionary = CSDictionary<TestItems>()
        let testItem = TestItems()
        testDictionary.add(item: testItem, withKey: "First")

        XCTAssertEqual(testDictionary.count, 1)
    }

    func testCanAddMultipleItem() {
        var testDictionary = CSDictionary<TestItems>()
        let testItem = TestItems()
        testDictionary.add(item: testItem, withKey: "First")
        testDictionary.add(item: testItem, withKey: "Second")
        testDictionary.add(item: testItem, withKey: "Third")

        XCTAssertEqual(testDictionary.count, 3)
    }

    func testCanReplaceItem() {
        var testDictionary = CSDictionary<TestItems>()
        let testItem = TestItems()
        testDictionary.add(item: testItem, withKey: "First")
        testDictionary.add(item: testItem, withKey: "Second")
        testDictionary.add(item: testItem, withKey: "Second")

        XCTAssertEqual(testDictionary.count, 2)
    }

    func testCanAddItemWithSubscript() {
        var testDictionary = CSDictionary<TestItems>()
        let testItem = TestItems()

        testDictionary["Item1"] = testItem
        XCTAssertEqual(testDictionary.count, 1)
    }

    func testCanRetrieveItemWithSubscript() {
        var testDictionary = CSDictionary<TestItems>()
        let testItem = TestItems()
        testDictionary.add(item: testItem, withKey: "First")
        testDictionary.add(item: testItem, withKey: "Second")
        testDictionary.add(item: testItem, withKey: "Third")

        // Can retrieve an item
        XCTAssertNotNil(testDictionary["Second"])

        // Get nil if item does not exist
        XCTAssertNil(testDictionary["NotThere"])

        // Can read values from returned item
        XCTAssertEqual(testDictionary["Third"]?.itemValue1, "Item Value 1")
    }

    func testCanRemoveItem() {
        var testDictionary = CSDictionary<TestItems>()
        let testItem = TestItems()
        testDictionary.add(item: testItem, withKey: "First")
        testDictionary.add(item: testItem, withKey: "Second")
        testDictionary.add(item: testItem, withKey: "Third")

        XCTAssertEqual(testDictionary.count, 3)

        testDictionary.remove(itemWithKey: "Second")
        XCTAssertEqual(testDictionary.count, 2)
        XCTAssertNil(testDictionary["Second"])
    }

    func testCanRemoveItemByIndex() {
        var testDictionary = CSDictionary<TestItems>()
        let testItem = TestItems()
        testDictionary.add(item: testItem, withKey: "First")
        testDictionary.add(item: testItem, withKey: "Second")
        testDictionary.add(item: testItem, withKey: "Third")

        XCTAssertEqual(testDictionary.count, 3)

        testDictionary.remove(at: 1)
        XCTAssertEqual(testDictionary.count, 2)
        XCTAssertNil(testDictionary["Second"])
    }

    func testCanIterateItems() {
        var testDictionary = CSDictionary<TestItems>()
        let testItem = TestItems()
        testDictionary.add(item: testItem, withKey: "First")
        testDictionary.add(item: testItem, withKey: "Second")
        testDictionary.add(item: testItem, withKey: "Third")

        var index = 0
        let keys = ["First", "Second", "Third"]
        for (key, value) in testDictionary {
            XCTAssertNotNil(key)
            XCTAssertNotNil(value)

            XCTAssertEqual(key, keys[index])
            XCTAssertEqual(value.itemNumber2, 2)

            index += 1
        }
    }

    func testCanTestIfItemExists() {
        var testDictionary = CSDictionary<TestItems>()
        let testItem = TestItems()
        testDictionary.add(item: testItem, withKey: "First")
        testDictionary.add(item: testItem, withKey: "Second")
        testDictionary.add(item: testItem, withKey: "Third")

        XCTAssertTrue(testDictionary.itemExists(withKey: "Second"))
        XCTAssertFalse(testDictionary.itemExists(withKey: "NotThere"))
    }

}
