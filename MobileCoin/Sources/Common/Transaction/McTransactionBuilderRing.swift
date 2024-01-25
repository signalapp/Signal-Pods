//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

final class McTransactionBuilderRing {
    private let ptr: OpaquePointer

    init(ring: [(TxOut, TxOutMembershipProof)]) {
        // Safety: mc_transaction_builder_ring_create should never return nil.
        self.ptr = withMcInfallible(mc_transaction_builder_ring_create)

        for (txOut, membershipProof) in ring {
            addElement(txOut: txOut, membershipProof: membershipProof)
        }
    }

    deinit {
        mc_transaction_builder_ring_free(ptr)
    }

    func addElement(txOut: TxOut, membershipProof: TxOutMembershipProof) {
        txOut.serializedData.asMcBuffer { txOutBytesPtr in
            membershipProof.serializedData.asMcBuffer { membershipProofDataPtr in
                // Safety: mc_transaction_builder_ring_add_element should never return nil.
                withMcInfallible {
                    mc_transaction_builder_ring_add_element(
                        ptr,
                        txOutBytesPtr,
                        membershipProofDataPtr)
                }
            }
        }
    }

    func withUnsafeOpaquePointer<R>(_ body: (OpaquePointer) throws -> R) rethrows -> R {
        try body(ptr)
    }
}
