//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable colon

import Foundation

struct AnyInfiniteIterator<Element> {
    private let box: AnyInfiniteIteratorBoxBase<Element>

    init<I: InfiniteIteratorProtocol>(_ base: I) where I.Element == Element {
        self.box = InfiniteIteratorBox(base)
    }

    init(_ body: @escaping () -> Element) {
        self.box = InfiniteIteratorBox(ClosureBasedInfiniteIterator(body))
    }
}

extension AnyInfiniteIterator: InfiniteIteratorProtocol {
    func next() -> Element {
        box.next()
    }
}

private class AnyInfiniteIteratorBoxBase<Element>: InfiniteIteratorProtocol {
    // swiftlint:disable unavailable_function
    func next() -> Element {
        // This condition should never be reached and indicates a programming error.
        fatalError("Must be overridden")
    }
    // swiftlint:enable unavailable_function
}

private final class InfiniteIteratorBox<Base: InfiniteIteratorProtocol>:
    AnyInfiniteIteratorBoxBase<Base.Element>
{
    init(_ base: Base) { self._base = base }

    override func next() -> Base.Element { _base.next() }

    var _base: Base
}

private struct ClosureBasedInfiniteIterator<Element>: InfiniteIteratorProtocol {
    let body: () -> Element

    init(_ body: @escaping () -> Element) {
        self.body = body
    }

    func next() -> Element { body() }
}
