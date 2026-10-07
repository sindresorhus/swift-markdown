/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2026 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

@testable import Markdown
import XCTest

class ListTightnessTests: XCTestCase {
    func testTightLists() {
        let document = Document(parsing: "- A\n- B\n\n1. A\n2. B")
        XCTAssertEqual(true, (document.child(at: 0) as? UnorderedList)?.isTight)
        XCTAssertEqual(true, (document.child(at: 1) as? OrderedList)?.isTight)
    }

    func testLooseListWithBlankLineBetweenItems() {
        let document = Document(parsing: "- A\n\n- B")
        XCTAssertEqual(false, (document.child(at: 0) as? UnorderedList)?.isTight)
    }

    func testLooseListWithBlankLineInsideAnItem() {
        let document = Document(parsing: "1. A\n\n   More.\n2. B")
        XCTAssertEqual(false, (document.child(at: 0) as? OrderedList)?.isTight)
    }

    func testNestedListsHaveTheirOwnTightness() {
        let document = Document(parsing: "- A\n\n  - B\n  - C\n\n- D")
        let outer = document.child(at: 0) as? UnorderedList
        let inner = outer?.child(through: [(0, ListItem.self), (1, UnorderedList.self)]) as? UnorderedList
        XCTAssertEqual(false, outer?.isTight)
        XCTAssertEqual(true, inner?.isTight)
    }

    func testListsInBlockQuotesAndAfterHardBreaks() {
        let document = Document(parsing: "> - A\\\n>   B\n> - C")
        let list = document.child(through: [(0, BlockQuote.self), (0, UnorderedList.self)]) as? UnorderedList
        XCTAssertEqual(true, list?.isTight)
    }

    func testBuiltListsAreTight() {
        XCTAssertTrue(UnorderedList(ListItem(Paragraph(Text("A")))).isTight)
        XCTAssertTrue(OrderedList(ListItem(Paragraph(Text("A")))).isTight)
    }

    func testChangingTheStartIndexKeepsTheTightness() {
        var list = Document(parsing: "1. A\n\n2. B").child(at: 0) as! OrderedList
        list.startIndex = 5
        XCTAssertFalse(list.isTight)
    }
}
