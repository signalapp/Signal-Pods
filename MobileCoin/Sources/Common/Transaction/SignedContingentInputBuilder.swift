//
//  Copyright (c) 2020-2022 MobileCoin. All rights reserved.
//
// swiftlint:disable function_parameter_count function_default_parameter_at_end
// swiftlint:disable closure_body_length
import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

enum SignedContingentInputBuilderError: Error {
    case invalidInput(String)
    case requiresBlockVersion3(String)
    case attestationVerificationFailed(String)
}

extension SignedContingentInputBuilderError: CustomStringConvertible {
    var description: String {
        "SignedContingentInput builder error: " + {
            switch self {
            case .invalidInput(let reason):
                return "Invalid input: \(reason)"
            case .requiresBlockVersion3(let reason):
                return "Invalid Block Version: \(reason)"
            case .attestationVerificationFailed(let reason):
                return "Attestation verification failed: \(reason)"
            }
        }()
    }
}

final class SignedContingentInputBuilder {
    private let tombstoneBlockIndex: UInt64

    private let ptr: OpaquePointer

    private let memoBuilder: TxOutMemoBuilder

    // Caching ring to replace membership proofs after sci creation.
    // Mobilecoin removes them to save space, expecting the consumer of the SCI
    // to recreate. For now, as a workaround, we're caching the ring to pass in to the build
    // function so libmobilecoin can restore the proofs in the SCI immediately
    // after mobilecoin lib creates it.
    private let ring: McTransactionBuilderRing

    private init(
        tombstoneBlockIndex: UInt64,
        fogResolver: FogResolver = FogResolver(),
        memoBuilder: TxOutMemoBuilder = DefaultMemoBuilder(),
        blockVersion: BlockVersion,
        viewPrivateKey: RistrettoPrivate,
        subaddressSpendPrivateKey: RistrettoPrivate,
        preparedTxInput: PreparedTxInput
    ) throws {
        self.tombstoneBlockIndex = tombstoneBlockIndex
        self.memoBuilder = memoBuilder
        let result: Result<OpaquePointer, TransactionBuilderError>

        let ring = McTransactionBuilderRing(ring: preparedTxInput.ring)
        self.ring = ring
        result = memoBuilder.withUnsafeOpaquePointer { memoBuilderPtr in
            fogResolver.withUnsafeOpaquePointer { fogResolverPtr in
                viewPrivateKey.asMcBuffer { viewPrivateKeyPtr in
                    subaddressSpendPrivateKey.asMcBuffer { subaddressSpendPrivateKeyPtr in
                        ring.withUnsafeOpaquePointer { ringPtr in

                            // Safety: mc_signed_contingent_input_builder_create should never
                            //         return nil.
                            withMcError { errorPtr in
                                mc_signed_contingent_input_builder_create(
                                    blockVersion,
                                    tombstoneBlockIndex,
                                    fogResolverPtr,
                                    memoBuilderPtr,
                                    viewPrivateKeyPtr,
                                    subaddressSpendPrivateKeyPtr,
                                    preparedTxInput.realInputIndex,
                                    ringPtr,
                                    &errorPtr)
                            }.mapError {
                                switch $0.errorCode {
                                case .invalidInput:
                                    return .invalidInput("\(redacting: $0.description)")
                                default:
                                    // Safety: mc_signed_contingent_input_builder_create should not
                                    //         throw non-documented errors.
                                    logger.fatalError("Unhandled LibMobileCoin error: " +
                                        "\(redacting: $0)")
                                }
                            }
                        }
                    }
                }
            }
        }
        self.ptr = try result.get()
    }

    deinit {
        mc_signed_contingent_input_builder_free(ptr)
    }
}

extension SignedContingentInputBuilder {
    static func build(
        inputs: [PreparedTxInput],
        accountKey: AccountKey,
        memoType: MemoType,
        amountToSend: Amount,
        amountToReceive: Amount,
        tombstoneBlockIndex: UInt64,
        fogResolver: FogResolver,
        blockVersion: BlockVersion,
        rng: MobileCoinRng
    ) -> Result<SignedContingentInput, TransactionBuilderError> {
        let builder: SignedContingentInputBuilder

        let possibleInputs = inputs.filter { $0.knownTxOut.amount.value >= amountToSend.value }
        guard possibleInputs.count > 0 else {
            return .failure(.invalidInput("Defragmentation Required"))
        }

        let input = possibleInputs.min { $0.knownTxOut.amount.value < $1.knownTxOut.amount.value }

        guard let input = input else {
            return .failure(.invalidInput("Unexpected error - unable to find valid input"))
        }

        let subaddressIndex = input.subaddressIndex
        guard let spendPrivateKey = accountKey.privateKeys(for: subaddressIndex)?.spendKey else {
            return .failure(.invalidInput("Tx subaddress index out of bounds"))
        }

        do {
            builder = try SignedContingentInputBuilder(
                tombstoneBlockIndex: tombstoneBlockIndex,
                fogResolver: fogResolver,
                memoBuilder: memoType.createMemoBuilder(accountKey: accountKey),
                blockVersion: blockVersion,
                viewPrivateKey: accountKey.viewPrivateKey,
                subaddressSpendPrivateKey: spendPrivateKey,
                preparedTxInput: input)
        } catch {
            guard let error = error as? TransactionBuilderError else {
                return .failure(.invalidInput("Unknown Error"))
            }
            return .failure(error)
        }

        if case .failure(let error) = builder.addRequiredOutput(
            publicAddress: accountKey.publicAddress,
            amount: amountToReceive,
            rng: rng) {
            return .failure(error)
        }

        // add required change output
        let changeValue = input.knownTxOut.amount.value - amountToSend.value
        if changeValue > 0 {
            if case .failure(let error) = builder.addRequiredChangeOutput(
                accountKey: accountKey,
                amount: Amount(value: changeValue, tokenId: amountToSend.tokenId),
                rng: rng) {
                return .failure(error)
            }
        }

        return builder.build(rng: rng)
    }
}

extension SignedContingentInputBuilder {
    private func addRequiredOutput(
        publicAddress: PublicAddress,
        amount: Amount,
        rng: MobileCoinRng
    ) -> Result<TxOut, TransactionBuilderError> {
        SignedContingentInputBuilderUtils.addRequiredOutput(
            ptr: ptr,
            publicAddress: publicAddress,
            amount: amount,
            rng: rng)
    }

    private func addRequiredChangeOutput(
        accountKey: AccountKey,
        amount: Amount,
        rng: MobileCoinRng
    ) -> Result<TxOut, TransactionBuilderError> {
        SignedContingentInputBuilderUtils.addRequiredChangeOutput(
            ptr: ptr,
            accountKey: accountKey,
            amount: amount,
            rng: rng)
    }

    private func build(
        rng: MobileCoinRng
    ) -> Result<SignedContingentInput, TransactionBuilderError> {
        SignedContingentInputBuilderUtils.build(ptr: ptr, rng: rng, ring: self.ring)
    }
}
