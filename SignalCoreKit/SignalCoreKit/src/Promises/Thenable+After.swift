//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public extension Guarantee where Value == Void {
    static func after(seconds: TimeInterval) -> Guarantee<Void> {
        let (guarantee, future) = Guarantee<Void>.pending()
        DispatchQueue.global().asyncAfter(deadline: .now() + seconds) {
            future.resolve()
        }
        return guarantee
    }
}
