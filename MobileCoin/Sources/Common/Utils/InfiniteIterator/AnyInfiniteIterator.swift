//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

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
    func next() -> Element {
        // This condition should never be reached and indicates a programming error.
        logger.fatalError("Must be overridden")
    }
}

private final class InfiniteIteratorBox<Base>: AnyInfiniteIteratorBoxBase<Base.Element>
    where Base: InfiniteIteratorProtocol
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
