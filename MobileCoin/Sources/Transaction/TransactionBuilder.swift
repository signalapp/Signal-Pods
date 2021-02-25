//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable function_parameter_count function_default_parameter_at_end

import Foundation
import LibMobileCoin

final class TransactionBuilder {
    private let tombstoneBlockIndex: UInt64

    private let ptr: OpaquePointer

    private init(
        fee: UInt64,
        tombstoneBlockIndex: UInt64,
        fogResolver: FogResolver = FogResolver()
    ) {
        self.tombstoneBlockIndex = tombstoneBlockIndex
        self.ptr = fogResolver.withUnsafeOpaquePointer { fogResolverPtr in
            // Safety: mc_transaction_builder_create should never return nil.
            withMcInfallible {
                mc_transaction_builder_create(fee, tombstoneBlockIndex, fogResolverPtr)
            }
        }
    }

    deinit {
        mc_transaction_builder_free(ptr)
    }

    private func addInput(preparedTxInput: PreparedTxInput, accountKey: AccountKey) throws {
        try addInput(
            preparedTxInput: preparedTxInput,
            viewPrivateKey: accountKey.viewPrivateKey,
            subaddressSpendPrivateKey: accountKey.subaddressSpendPrivateKey)
    }

    private func addInput(
        preparedTxInput: PreparedTxInput,
        viewPrivateKey: RistrettoPrivate,
        subaddressSpendPrivateKey: RistrettoPrivate
    ) throws {
        let ring = McTransactionBuilderRing(ring: preparedTxInput.ring)
        try viewPrivateKey.asMcBuffer { viewPrivateKeyPtr in
            try subaddressSpendPrivateKey.asMcBuffer { subaddressSpendPrivateKeyPtr in
                try ring.withUnsafeOpaquePointer { ringPtr in
                    try withMcError { errorPtr in
                        mc_transaction_builder_add_input(
                            ptr,
                            viewPrivateKeyPtr,
                            subaddressSpendPrivateKeyPtr,
                            preparedTxInput.realInputIndex,
                            ringPtr,
                            &errorPtr)
                    }.get()
                }
            }
        }
    }

    private func addOutput(
        publicAddress: PublicAddress,
        amount: UInt64,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) throws -> (txOut: TxOut, receipt: Receipt) {
        var confirmationNumberData = Data32()
        let txOut = try publicAddress.withUnsafeCStructPointer { publicAddressPtr in
            try withMcRngCallback(rng: rng, rngContext: rngContext) { rngCallbackPtr in
                try confirmationNumberData.asMcMutableBuffer { confirmationNumberPtr -> TxOut in
                    let txOutData = try Data(withMcDataBytes: { errorPtr in
                        mc_transaction_builder_add_output(
                            ptr,
                            amount,
                            publicAddressPtr,
                            rngCallbackPtr,
                            confirmationNumberPtr,
                            &errorPtr)
                    })
                    guard let txOut = TxOut(serializedData: txOutData) else {
                        // Safety: mc_transaction_builder_add_output should always return valid
                        // data on success.
                        fatalError("\(Self.self).\(#function): " +
                            "mc_transaction_builder_add_output return invalid data.")
                    }
                    return txOut
                }
            }
        }
        let confirmationNumber = TxOutConfirmationNumber(confirmationNumberData)
        let receipt = try Receipt(
            txOut: txOut,
            confirmationNumber: confirmationNumber,
            tombstoneBlockIndex: tombstoneBlockIndex)
        return (txOut, receipt)
    }

    private func build(
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) throws -> Transaction {
        let txBytes = try withMcRngCallback(rng: rng, rngContext: rngContext) { rngCallbackPtr in
            try Data(withMcDataBytes: { errorPtr in
                mc_transaction_builder_build(ptr, rngCallbackPtr, &errorPtr)
            })
        }
        guard let transaction = Transaction(serializedData: txBytes) else {
            // Safety: mc_transaction_builder_build should always return valid data on success.
            fatalError(
                "\(Self.self).\(#function): mc_transaction_builder_build return invalid data.")
        }
        return transaction
    }
}

extension TransactionBuilder {
    static func build(
        inputs: [PreparedTxInput],
        accountKey: AccountKey,
        to recipient: PublicAddress,
        amount: UInt64,
        changeAddress: PublicAddress? = nil,
        fee: UInt64,
        tombstoneBlockIndex: UInt64,
        fogResolver: FogResolver,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) throws -> (transaction: Transaction, receipt: Receipt) {
        let (transaction, transactionReceipts) = try build(
            inputs: inputs,
            accountKey: accountKey,
            outputs: [(recipient, amount)],
            changeAddress: changeAddress,
            fee: fee,
            tombstoneBlockIndex: tombstoneBlockIndex,
            fogResolver: fogResolver,
            rng: rng,
            rngContext: rngContext)
        return (transaction, transactionReceipts[0])
    }

    static func build(
        inputs: [PreparedTxInput],
        accountKey: AccountKey,
        outputs: [(recipient: PublicAddress, amount: UInt64)],
        changeAddress: PublicAddress? = nil,
        fee: UInt64,
        tombstoneBlockIndex: UInt64,
        fogResolver: FogResolver,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) throws -> (transaction: Transaction, transactionReceipts: [Receipt]) {
        for (_, amount) in outputs {
            guard amount > 0 else {
                throw MalformedInput("Cannot send 0 MOB")
            }
        }

        for txOut in inputs.map({ $0.knownTxOut }) {
            print("TxOut to spend: " +
                "index: \(txOut.globalIndex), " +
                "value: \(txOut.value), " +
                "pubkey: \(txOut.publicKey.base64EncodedString())")
        }
        print("Spending \(inputs.count) TxOuts totaling " +
            "\(inputs.map { $0.knownTxOut.value }.reduce(0, +)) picoMOB")

        let outputs = try outputsAddingChangeOutputIfNeeded(
            inputs: inputs,
            outputs: outputs,
            changeAddress: changeAddress,
            fee: fee)

        let builder = TransactionBuilder(
            fee: fee,
            tombstoneBlockIndex: tombstoneBlockIndex,
            fogResolver: fogResolver)
        for input in inputs {
            try builder.addInput(preparedTxInput: input, accountKey: accountKey)
        }
        let transactionReceipts = try outputs.map { recipient, amount in
            try builder.addOutput(
                publicAddress: recipient,
                amount: amount,
                rng: rng,
                rngContext: rngContext
            ).receipt
        }
        let transaction = try builder.build(rng: rng, rngContext: rngContext)

        return (transaction, transactionReceipts)
    }

    static func output(
        publicAddress: PublicAddress,
        amount: UInt64,
        tombstoneBlockIndex: UInt64,
        fogResolver: FogResolver = FogResolver(),
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) throws -> (txOut: TxOut, receipt: Receipt) {
        let transactionBuilder = TransactionBuilder(
            fee: 0,
            tombstoneBlockIndex: tombstoneBlockIndex,
            fogResolver: fogResolver)
        return try transactionBuilder.addOutput(
            publicAddress: publicAddress,
            amount: amount,
            rng: rng,
            rngContext: rngContext
        )
    }
}

extension TransactionBuilder {
    private static func outputsAddingChangeOutputIfNeeded(
        inputs: [PreparedTxInput],
        outputs: [(recipient: PublicAddress, amount: UInt64)],
        changeAddress: PublicAddress?,
        fee: UInt64
    ) throws -> [(recipient: PublicAddress, amount: UInt64)] {
        let inputAmount = inputs.map { $0.knownTxOut.value }.reduce(0, +)
        let suppliedOutputsAmountPlusFee = outputs.map { $0.amount }.reduce(0, +) + fee

        guard inputAmount >= suppliedOutputsAmountPlusFee else {
            throw MalformedInput("Total input amount (\(inputAmount)) < total output amount + " +
                "fee (\(suppliedOutputsAmountPlusFee))")
        }

        var outputArray = outputs
        if inputAmount > suppliedOutputsAmountPlusFee {
            guard let changeAddress = changeAddress else {
                throw MalformedInput("Total input amount (\(inputAmount)) exceeds total output " +
                    "amount plus fee (\(suppliedOutputsAmountPlusFee)) but change address was " +
                    "not supplied")
            }
            let changeAmount = inputAmount - suppliedOutputsAmountPlusFee
            outputArray.append((changeAddress, changeAmount))
        }
        return outputArray
    }
}

private final class McTransactionBuilderRing {
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
