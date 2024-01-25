// swiftlint:disable:this file_name

//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

extension String {
    init(mcString: UnsafeMutablePointer<CChar>) {
        defer {
            mc_string_free(mcString)
        }
        self.init(cString: mcString)
    }
}
