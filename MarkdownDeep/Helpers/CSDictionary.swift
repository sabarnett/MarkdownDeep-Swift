// Project: MarkdownDeep
//
// Copyright © 2020 Steven Barnett. All rights reserved. 
//

import Foundation

fileprivate struct CSDictionaryItem<T> {
    var key: String
    var value: T

    init(key: String, value: T) {
        self.key = key
        self.value = value
    }
}

struct CSDictionary<T>: Sequence {

    private var itemList: [CSDictionaryItem<T>] = []

    /// Add a new item to the collection or replace an existing item. If
    /// an item with the specified key exists, it will be replaced in-place.
    ///
    /// - Parameters:
    ///   - item: The item to be added to the collection
    ///   - key: The key of the item (case insensitive)
    mutating func add(item: T, withKey key: String) {
        guard key.count > 0 else { return }

        if let index = itemIndex(withKey: key) {
            itemList[index].value = item
            return
        }

        itemList.append(CSDictionaryItem(key: key, value: item))
    }

    /// Looks for the specified key in the collection. If a matching item is found,
    /// the it is removed from the collection. If it is not found, the request is
    /// ignored. No error is thrown.
    ///
    /// - Parameter key: The key of the item to remove
    mutating func remove(itemWithKey key: String) {
        guard key.count > 0 else { return }

        if let index = itemIndex(withKey: key) {
            itemList.remove(at: index)
        }
    }

    /// Removes an item at a specific index in the collection. If the index is invalid,
    /// the request is ignored.
    ///
    /// - Parameter index: The index of the item in the collection
    mutating func remove(at index: Int) {
        // is index valid?
        guard index >= 0 && index < itemList.count else {
            return
        }

        itemList.remove(at: index)
    }

    mutating func removeAll() {
        itemList.removeAll()
    }

    /// Returns the nuber of items in the collection
    var count: Int {
        get {
            return itemList.count
        }
    }
    
    subscript(index: String) ->T? {
        get {
            guard index.count > 0 else { return nil }
            return findItem(withKey: index)
        }
        mutating set(newElement) {
            guard index.count > 0 else { return }
            if let element = newElement {
                self.add(item: element, withKey: index)
            }
        }
    }

    /// Returns an iterator for the collection.
    func makeIterator() -> ItemsIterator<String, T> {
        return ItemsIterator<String, T>(self)
    }

    /// Returns the index of the item in the collection if it exists, else
    /// returns -1 if the key does not exist.
    /// - Parameter key: The key of the item whos index we want
    func indexOf(key: String) -> Int {
        guard key.count > 0 else { return -1 }

        if let index = itemIndex(withKey: key) {
            return index
        }
        
        return -1
    }

    /// Returns True if the ket exists in the dictionary, else false.
    /// - Parameter key: The key of the item to locate
    func itemExists(withKey key: String) -> Bool {
        guard key.count > 0 else { return false }
        return findItem(withKey: key) !=  nil
    }

    /// returns the key/value tuple of the item at the specified index
    /// - Parameter index: The index of the item to retrieve. Returns nil if
    /// the index is invalid.
    func itemAt(index: Int) -> (String, T)? {
        guard index >= 0 && index < itemList.count else {
            return nil
        }

        return (itemList[index].key, itemList[index].value)
    }

    // MARK:- Internal helper functions

    private func findItem(withKey: String) -> T? {

        let testKey = withKey.lowercased()
        if let itemIndex = itemList.firstIndex(where: { (item) -> Bool in
            return item.key.lowercased() == testKey
        }) {
            // We got an item index, so return that item
            return itemList[itemIndex].value
        }

        // Item does not exist, return a nil
        return nil
    }

    private func itemIndex(withKey: String) -> Int? {
        let testKey = withKey.lowercased()

        if let itemIndex = itemList.firstIndex(where: { (item) -> Bool in
            return item.key.lowercased() == testKey
        }) {
            // We got an item index, so return that item
            return itemIndex
        }
        return nil
    }
}

/// Iterator to iterate over the dictionary entries.
struct ItemsIterator<String, T>: IteratorProtocol {
    typealias Element = (String, T)

    private let collection: CSDictionary<T>
    private var index = 0

    init(_ collection: CSDictionary<T>) {
        self.collection = collection
    }

    mutating func next() -> (String, T)? {
        defer {
            index += 1
        }

        if index < collection.count {
            return (collection.itemAt(index: index) as! (String, T))
        } else {
            return nil
        }
    }
}
