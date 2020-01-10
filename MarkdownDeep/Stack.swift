// Project: MarkdownDeep
//
// Copyright © 2019 Steven Barnett. All rights reserved. 
//

import Foundation

struct Stack<T> {

    private var items: [T] = []

    func peek() -> T {
        guard let topElement = items.first else { fatalError("This stack is empty.") }
        return topElement
    }

    mutating func pop() -> T {
        return items.removeFirst()
    }

    mutating func push(_ element: T) {
        items.insert(element, at: 0)
    }

    var count : Int {
        get {
            return items.count
        }
    }
}
