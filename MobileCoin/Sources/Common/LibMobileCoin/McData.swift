//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

final class McData {
    let ptr: OpaquePointer

    init(_ ptr: OpaquePointer) {
        self.ptr = ptr
    }

    deinit {
        mc_data_free(ptr)
    }

    var bytes: Data {
        Data(withMcMutableBufferInfallible: { bufferPtr in
            mc_data_get_bytes(ptr, bufferPtr)
        })
    }
}

extension Data {
    static func make(withMcDataBytes body: (inout UnsafeMutablePointer<McError>?) -> OpaquePointer?)
        -> Result<Data, LibMobileCoinError>
    {
        withMcError(body).map {
            let mcData = McData($0)
            return mcData.bytes
        }
    }
}
