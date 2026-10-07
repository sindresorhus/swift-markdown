/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

/// A markup element that can contain only `ListItem`s as children and require no other information.
public protocol ListItemContainer: BlockMarkup {
    /// Create a list from a sequence of items.
    init<Items: Sequence>(_ items: Items) where  Items.Element == ListItem
}

// MARK: - Public API

public extension ListItemContainer {
    /// Whether the list is tight, as CommonMark defines it: no blank line separates its items, or the blocks inside an item.
    ///
    /// The items of a tight list have no paragraph around their text when rendered as HTML. A list made in code is tight.
    var isTight: Bool {
        switch raw.markup.data {
        case let .orderedList(_, isTight), let .unorderedList(isTight):
            return isTight
        default:
            fatalError("\(self) markup wrapped unexpected \(raw)")
        }
    }

    /// Create a list with one item.
    init(_ item: ListItem) {
        self.init(CollectionOfOne(item))
    }
    /// Create a list with the given `ListItem`s.
    init(_ items: ListItem...) {
        self.init(items)
    }

    /// The items of the list.
    ///
    /// - Precondition: All children of a `ListItemContainer`
    ///   must be a `ListItem`.
    var listItems: LazyMapSequence<MarkupChildren, ListItem> {
        return children.lazy.map { $0 as! ListItem }
    }

    /// Replace all list items with a sequence of items.
    mutating func setListItems<Items: Sequence>(_ newItems: Items) where Items.Element == ListItem {
        replaceItemsInRange(0..<childCount, with: newItems)
    }

    /// Replace list items in a range with a sequence of items.
    mutating func replaceItemsInRange<Items: Sequence>(_ range: Range<Int>, with incomingItems: Items) where Items.Element == ListItem {
        var rawChildren = raw.markup.copyChildren()
        rawChildren.replaceSubrange(range, with: incomingItems.map { $0.raw.markup })
        let newRaw = raw.markup.withChildren(rawChildren)
        _data = _data.replacingSelf(newRaw)
    }

    /// Append an item to the list.
    mutating func appendItem(_ item: ListItem) {
        replaceItemsInRange(childCount..<childCount, with: CollectionOfOne(item))
    }
}
