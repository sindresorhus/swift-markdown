/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021-2023 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

/// An auxiliary aside element interpreted from a block quote.
///
/// Asides are written as a block quote starting with a special plain-text tag,
/// such as `note:` or `tip:`:
///
/// ```markdown
/// > Tip: This is a `tip` aside.
/// > It may have a presentation similar to a block quote, but with a
/// > different meaning, as it doesn't quote speech.
/// ```
public struct Aside {
    /// Describes the different kinds of aside.
    public struct Kind: RawRepresentable, CaseIterable, Hashable, Sendable {
        /// A "note" aside.
        public static let note = Kind(rawValue: "Note")!
        
        /// A "tip" aside.
        public static let tip = Kind(rawValue: "Tip")!
        
        /// An "important" aside.
        public static let important = Kind(rawValue: "Important")!
        
        /// An "experiment" aside.
        public static let experiment = Kind(rawValue: "Experiment")!
        
        /// A "warning" aside.
        public static let warning = Kind(rawValue: "Warning")!
        
        /// An "attention" aside.
        public static let attention = Kind(rawValue: "Attention")!
        
        /// An "author" aside.
        public static let author = Kind(rawValue: "Author")!
        
        /// An "authors" aside.
        public static let authors = Kind(rawValue: "Authors")!
        
        /// A "bug" aside.
        public static let bug = Kind(rawValue: "Bug")!
        
        /// A "complexity" aside.
        public static let complexity = Kind(rawValue: "Complexity")!
        
        /// A "copyright" aside.
        public static let copyright = Kind(rawValue: "Copyright")!
        
        /// A "date" aside.
        public static let date = Kind(rawValue: "Date")!
        
        /// An "invariant" aside.
        public static let invariant = Kind(rawValue: "Invariant")!
        
        /// A "mutatingVariant" aside.
        public static let mutatingVariant = Kind(rawValue: "MutatingVariant")!
        
        /// A "nonMutatingVariant" aside.
        public static let nonMutatingVariant = Kind(rawValue: "NonMutatingVariant")!
        
        /// A "postcondition" aside.
        public static let postcondition = Kind(rawValue: "Postcondition")!
        
        /// A "precondition" aside.
        public static let precondition = Kind(rawValue: "Precondition")!
        
        /// A "remark" aside.
        public static let remark = Kind(rawValue: "Remark")!
        
        /// A "requires" aside.
        public static let requires = Kind(rawValue: "Requires")!
        
        /// A "since" aside.
        public static let since = Kind(rawValue: "Since")!
        
        /// A "todo" aside.
        public static let todo = Kind(rawValue: "ToDo")!
        
        /// A "version" aside.
        public static let version = Kind(rawValue: "Version")!
        
        /// A "throws" aside.
        public static let `throws` = Kind(rawValue: "Throws")!
        
        /// A "seeAlso" aside.
        public static let seeAlso = Kind(rawValue: "SeeAlso")!

        /// A "caution" aside, like a GitHub `[!CAUTION]` alert.
        public static let caution = Kind(rawValue: "Caution")!
        
        /// A collection of preconfigured aside kinds.
        public static var allCases: [Aside.Kind] {
            [
                note,
                tip,
                important,
                experiment,
                warning,
                attention,
                author,
                authors,
                bug,
                complexity,
                copyright,
                date,
                invariant,
                mutatingVariant,
                nonMutatingVariant,
                postcondition,
                precondition,
                remark,
                requires,
                since,
                todo,
                version,
                `throws`,
                seeAlso,
                caution,
            ]
        }
        
        /// The heading text to use when rendering this kind of aside.
        ///
        /// For multi-word asides this value may differ from the aside's ``rawValue``.
        /// For example, the ``seeAlso`` aside's `rawValue` is `"SeeAlso"` but its
        /// `displayName` is `"See Also"`.
        /// Likewise, ``nonMutatingVariant``'s `rawValue` is
        /// `"NonMutatingVariant"` and its `displayName` is `"Non-Mutating Variant"`.
        ///
        /// For simpler, single-word asides like ``bug``, the `displayName` and `rawValue` will
        /// be the same.
        public var displayName: String {
            switch self {
            case .seeAlso:
                return "See Also"
            case .nonMutatingVariant:
                return "Non-Mutating Variant"
            case .mutatingVariant:
                return "Mutating Variant"
            case .todo:
                return "To Do"
            default:
                return rawValue
            }
        }
        
        /// The underlying raw string value.
        public var rawValue: String
        
        /// Creates an aside kind with the specified raw value.
        /// - Parameter rawValue: The string the aside displays as its title.
        public init?(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    /// Determines the permissiveness of aside-tag parsing when using ``init(_:tagRequirement:)``.
    public enum TagRequirement: Equatable, Sendable {
        /// Only allow asides with a single-word aside tag, such as `Warning:` or `Important:`
        case requireSingleWordTag
        /// Require a aside tag, but allow it to be multiple words, such as `See Also:`
        case requireAnyLengthTag
        /// Convert all block-quotes into asides, treating asides with no kind tag as ``Aside/Kind/note`` asides.
        case tagNotRequired
    }

    /// The kind of aside interpreted from the initial text of the ``BlockQuote``.
    public var kind: Kind

    /// The block elements of the aside taken from the ``BlockQuote``,
    /// excluding the initial text tag.
    public var content: [BlockMarkup]

    /// Create an aside from a block quote.
    public init(_ blockQuote: BlockQuote) {
        // Try to find an initial `tag:` text at the beginning.
        guard let kindTag = blockQuote.parseAsideTag(tagRequirement: .tagNotRequired) else {
            // Otherwise, default to a note aside.
            self.kind = .note
            self.content = Array(blockQuote.blockChildren)
            return
        }

        self.kind = Kind(rawValue: kindTag.tag)!
        self.content = Array(kindTag.newBlockQuote.blockChildren)
    }

    /// Create an aside from a block quote if it contains a kind tag that matches the given requirement.
    public init?(_ blockQuote: BlockQuote, tagRequirement: TagRequirement = .tagNotRequired) {
        guard tagRequirement != .tagNotRequired else {
            self = .init(blockQuote)
            return
        }

        guard let kindTag = blockQuote.parseAsideTag(tagRequirement: tagRequirement) else {
            return nil
        }

        self.kind = Kind(rawValue: kindTag.tag)!
        self.content = Array(kindTag.newBlockQuote.blockChildren)
    }

    /// Create an aside from a block quote that is a GitHub alert, or `nil` if it is not one.
    ///
    /// A GitHub alert starts with a marker alone on its first line, in any case: `[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, or `[!CAUTION]`. These are the kinds ``Kind/note``, ``Kind/tip``, ``Kind/important``, ``Kind/warning``, and ``Kind/caution``. Like on GitHub, the alert needs content after the marker.
    ///
    /// ```markdown
    /// > [!NOTE]
    /// > Useful information that users should know.
    /// ```
    ///
    /// The ``content`` is the block quote without the marker.
    ///
    /// - Note: GitHub does not render alerts that are nested in other elements, like a list. Check the parent of the block quote to do the same.
    public init?(gitHubAlert blockQuote: BlockQuote) {
        guard let alert = blockQuote.parseGitHubAlertMarker() else {
            return nil
        }

        self.kind = alert.kind
        self.content = alert.content
    }
}

extension BlockQuote {
    func parseGitHubAlertMarker() -> (kind: Aside.Kind, content: [BlockMarkup])? {
        let kinds: [String: Aside.Kind] = [
            "NOTE": .note,
            "TIP": .tip,
            "IMPORTANT": .important,
            "WARNING": .warning,
            "CAUTION": .caution,
        ]

        guard
            let paragraph = child(at: 0) as? Paragraph,
            let marker = paragraph.child(at: 0) as? Text,
            marker.string.hasPrefix("[!"),
            marker.string.hasSuffix("]"),
            let kind = kinds[marker.string.dropFirst(2).dropLast().uppercased()]
        else {
            return nil
        }

        // The marker is alone on its line: a line break follows it, or it is the whole paragraph and other blocks follow.
        let next = paragraph.child(at: 1)

        guard next is SoftBreak || next is LineBreak || (paragraph.childCount == 1 && childCount > 1) else {
            return nil
        }

        // The rest of the first paragraph, after the marker and its line break.
        let rest = (0..<paragraph.childCount).dropFirst(2).map { paragraph.raw.markup.child(at: $0) }

        guard !rest.isEmpty else {
            return (kind, Array(blockChildren.dropFirst()))
        }

        let restRange: SourceRange? = rest.first?.parsedRange.flatMap { first in
            paragraph.range.map { first.lowerBound..<$0.upperBound }
        }

        guard let newBlockQuote = _data.substitutingChild(.paragraph(parsedRange: restRange, rest), at: 0, preserveRange: true) as? BlockQuote else {
            return nil
        }

        return (kind, Array(newBlockQuote.blockChildren))
    }

    func parseAsideTag(tagRequirement: Aside.TagRequirement) -> (tag: String, newBlockQuote: BlockQuote)? {
        guard let initialText = self.child(through: [
            (0, Paragraph.self),
            (0, Text.self),
        ]) as? Text, let firstColonIndex = initialText.string.firstIndex(of: ":") else {
            return nil
        }

        let kindTag = initialText.string[..<firstColonIndex]
        let trimmedText = initialText.string[initialText.string.index(after: firstColonIndex)...].drop {
            $0 == " " || $0 == "\t"
        }

        guard tagRequirement != .requireSingleWordTag || !kindTag.contains(" ") else {
            return nil
        }

        let shiftCount = kindTag.utf8.count + 1 + initialText.string[firstColonIndex...].dropFirst().prefix(while: {
            $0 == " " || $0 == "\t"
        }).count
        let textRange: SourceRange? = initialText.range.map({ originalRange in
            var newStart = originalRange.lowerBound
            newStart.column = min(newStart.column + shiftCount, originalRange.upperBound.column)
            return newStart..<originalRange.upperBound
        })

        guard let newBlockQuote = self._data.substitutingChild(
            .text(parsedRange: textRange, string: String(trimmedText)),
            through: [0, 0],
            preserveRange: true) as? BlockQuote
        else {
            return nil
        }
        assert(
            newBlockQuote.range?.lowerBound.source == self.range?.lowerBound.source,
            "Parsing didn't lose the original source information"
        )

        return (String(kindTag), newBlockQuote)
    }
}
