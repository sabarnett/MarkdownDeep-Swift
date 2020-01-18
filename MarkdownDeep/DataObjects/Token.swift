//
//  MarkdownDeep for SWIFT
//     Copyright (C) 2020 Steven Barnett
//
//  This is a port of the C# version of MarkdownDeep...
//
//   MarkdownDeep - http://www.toptensoftware.com/markdowndeep
//     Copyright (C) 2010-2011 Topten Software
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this product except in compliance with the
//   License. You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing,
//   software distributed under the License is distributed on
//   an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//   either express or implied. See the License for the specific
//   language governing permissions and limitations under the License.
//
import Foundation

class Token: CustomStringConvertible, Equatable {

    public var type: TokenType
    public var startOffset: Int = 0
    public var length: Int = 0
    public var data: Any!

    // MARK:- Constructors

    init(_ type: TokenType, _ startOffset: Int, _ length: Int)  {
        self.type = type
        self.startOffset = startOffset
        self.length = length
    }

    init(_ type: TokenType, _ data: Any) {
        self.type = type
        self.data = data
    }

    // MARK:- CustomStringConvertible implementation

    var description: String {
        get {
            if (data == nil) {
                return "\(type.description) - \(startOffset) - \(length)"
            } else {
                return "\(type.description) - \(startOffset) - \(length) -> \(String(describing: data))"
            }
        }
    }

    // MARK:- Equatable implementation

    static func == (lhs: Token, rhs: Token) -> Bool {
        return lhs.description == rhs.description
    }

    static func != (lhs: Token, rhs: Token) -> Bool {
        return lhs.description != rhs.description
    }
}

