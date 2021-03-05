//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable function_parameter_count function_default_parameter_at_end
// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin

enum TransactionBuilderError: Error {
    case invalidInput(String)
}

extension TransactionBuilderError: CustomStringConvertible {
    public var description: String {
        "Transaction builder error: " + {
            switch self {
            case .invalidInput(let reason):
                return "Invalid input: \(reason)"
            }
        }()
    }
}

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

    private func addInput(preparedTxInput: PreparedTxInput, accountKey: AccountKey)
        -> Result<(), TransactionBuilderError>
    {
        addInput(
            preparedTxInput: preparedTxInput,
            viewPrivateKey: accountKey.viewPrivateKey,
            subaddressSpendPrivateKey: accountKey.subaddressSpendPrivateKey)
    }

    private func addInput(
        preparedTxInput: PreparedTxInput,
        viewPrivateKey: RistrettoPrivate,
        subaddressSpendPrivateKey: RistrettoPrivate
    ) -> Result<(), TransactionBuilderError> {
        let ring = McTransactionBuilderRing(ring: preparedTxInput.ring)
        return viewPrivateKey.asMcBuffer { viewPrivateKeyPtr in
            subaddressSpendPrivateKey.asMcBuffer { subaddressSpendPrivateKeyPtr in
                ring.withUnsafeOpaquePointer { ringPtr in
                    withMcError { errorPtr in
                        mc_transaction_builder_add_input(
                            ptr,
                            viewPrivateKeyPtr,
                            subaddressSpendPrivateKeyPtr,
                            preparedTxInput.realInputIndex,
                            ringPtr,
                            &errorPtr)
                    }.mapError { .invalidInput(String(describing: $0)) }
                }
            }
        }
    }

    private func addOutput(
        publicAddress: PublicAddress,
        amount: UInt64,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> Result<(txOut: TxOut, receipt: Receipt), TransactionBuilderError> {
        var confirmationNumberData = Data32()
        return publicAddress.withUnsafeCStructPointer { publicAddressPtr in
            withMcRngCallback(rng: rng, rngContext: rngContext) { rngCallbackPtr in
                confirmationNumberData.asMcMutableBuffer { confirmationNumberPtr in
                    Data.make(withMcDataBytes: { errorPtr in
                        mc_transaction_builder_add_output(
                            ptr,
                            amount,
                            publicAddressPtr,
                            rngCallbackPtr,
                            confirmationNumberPtr,
                            &errorPtr)
                    }).mapError { .invalidInput(String(describing: $0)) }
                }
            }
        }.map { txOutData in
            guard let txOut = TxOut(serializedData: txOutData) else {
                // Safety: mc_transaction_builder_add_output should always return valid data on
                // success.
                logger.fatalError("Error: \(Self.self).\(#function): " +
                    "mc_transaction_builder_add_output return invalid data.")
            }

            let confirmationNumber = TxOutConfirmationNumber(confirmationNumberData)
            let receipt = Receipt(
                txOut: txOut,
                confirmationNumber: confirmationNumber,
                tombstoneBlockIndex: tombstoneBlockIndex)
            return (txOut, receipt)
        }
    }

    private func build(
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> Result<Transaction, TransactionBuilderError> {
        withMcRngCallback(rng: rng, rngContext: rngContext) { rngCallbackPtr in
            Data.make(withMcDataBytes: { errorPtr in
                mc_transaction_builder_build(ptr, rngCallbackPtr, &errorPtr)
            }).mapError { .invalidInput(String(describing: $0)) }
        }.map { txBytes in
            guard let transaction = Transaction(serializedData: txBytes) else {
                // Safety: mc_transaction_builder_build should always return valid data on success.
                logger.fatalError("Error: \(Self.self).\(#function): " +
                    "mc_transaction_builder_build return invalid data.")
            }
            return transaction
        }
    }
}

extension TransactionBuilder {
    static func build(
        inputs: [PreparedTxInput],
        accountKey: AccountKey,
        to recipient: PublicAddress,
        amount: PositiveUInt64,
        changeAddress: PublicAddress? = nil,
        fee: UInt64,
        tombstoneBlockIndex: UInt64,
        fogResolver: FogResolver,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) -> Result<(transaction: Transaction, receipt: Receipt), TransactionBuilderError> {
        build(
            inputs: inputs,
            accountKey: accountKey,
            outputs: [(recipient, amount)],
            changeAddress: changeAddress,
            fee: fee,
            tombstoneBlockIndex: tombstoneBlockIndex,
            fogResolver: fogResolver,
            rng: rng,
            rngContext: rngContext
        ).map { transaction, transactionReceipts in
            (transaction, transactionReceipts[0])
        }
    }

    static func build(
        inputs: [PreparedTxInput],
        accountKey: AccountKey,
        outputs: [(recipient: PublicAddress, amount: PositiveUInt64)],
        changeAddress: PublicAddress? = nil,
        fee: UInt64,
        tombstoneBlockIndex: UInt64,
        fogResolver: FogResolver,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) -> Result<(transaction: Transaction, transactionReceipts: [Receipt]), TransactionBuilderError>
    {
        for txOut in inputs.map({ $0.knownTxOut }) {
            print("TxOut to spend: " +
                "index: \(txOut.globalIndex), " +
                "value: \(txOut.value), " +
                "pubkey: \(txOut.publicKey.base64EncodedString())")
        }
        print("Spending \(inputs.count) TxOuts totaling " +
            "\(inputs.map { $0.knownTxOut.value }.reduce(0, +)) picoMOB")

        return outputsAddingChangeOutputIfNeeded(
            inputs: inputs,
            outputs: outputs,
            changeAddress: changeAddress,
            fee: fee
        ).flatMap { outputs in
            let builder = TransactionBuilder(
                fee: fee,
                tombstoneBlockIndex: tombstoneBlockIndex,
                fogResolver: fogResolver)

            for input in inputs {
                if case .failure(let error) =
                    builder.addInput(preparedTxInput: input, accountKey: accountKey)
                {
                    return .failure(error)
                }
            }
            return outputs.map { recipient, amount in
                builder.addOutput(
                    publicAddress: recipient,
                    amount: amount.value,
                    rng: rng,
                    rngContext: rngContext
                ).map { $0.receipt }
            }.collectResult().flatMap { transactionReceipts in
                builder.build(rng: rng, rngContext: rngContext).map { transaction in
                    (transaction, transactionReceipts)
                }
            }
        }
    }

    static func output(
        publicAddress: PublicAddress,
        amount: UInt64,
        tombstoneBlockIndex: UInt64,
        fogResolver: FogResolver = FogResolver(),
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> Result<(txOut: TxOut, receipt: Receipt), TransactionBuilderError> {
        let transactionBuilder = TransactionBuilder(
            fee: 0,
            tombstoneBlockIndex: tombstoneBlockIndex,
            fogResolver: fogResolver)
        return transactionBuilder.addOutput(
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
        outputs: [(recipient: PublicAddress, amount: PositiveUInt64)],
        changeAddress: PublicAddress?,
        fee: UInt64
    ) -> Result<[(recipient: PublicAddress, amount: PositiveUInt64)], TransactionBuilderError> {
        let inputAmount = inputs.map { $0.knownTxOut.value }.reduce(0, +)
        let suppliedOutputsAmountPlusFee = outputs.map { $0.amount.value }.reduce(0, +) + fee

        guard inputAmount >= suppliedOutputsAmountPlusFee else {
            return .failure(.invalidInput(
                "Total input amount (\(inputAmount)) < total output amount + fee " +
                "(\(suppliedOutputsAmountPlusFee))"))
        }

        var outputArray = outputs
        if inputAmount > suppliedOutputsAmountPlusFee,
           let changeAmount = PositiveUInt64(inputAmount - suppliedOutputsAmountPlusFee)
        {
            guard let changeAddress = changeAddress else {
                return .failure(.invalidInput(
                    "Total input amount (\(inputAmount)) exceeds total output amount plus fee " +
                    "(\(suppliedOutputsAmountPlusFee)) but change address was not supplied"))
            }
            outputArray.append((changeAddress, changeAmount))
        }
        return .success(outputArray)
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
