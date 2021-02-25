//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

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
    init(withMcDataBytes body: (inout UnsafeMutablePointer<McError>?) -> OpaquePointer?) throws {
        let mcData = McData(try withMcError(body).get())
        self = mcData.bytes
    }
}
