
// Order matters.
#import <MobileCoinMinimal/attest.h>
#import <MobileCoinMinimal/transaction.h>

#import <CocoaLumberjack/CocoaLumberjack.h>
#ifdef DEBUG
static const NSUInteger ddLogLevel = DDLogLevelAll;
#else
static const NSUInteger ddLogLevel = DDLogLevelInfo;
#endif

bool mc_tx_out_validate_confirmation_number(
                                            const McBuffer* MC_NONNULL tx_out_public_key,
                                            const McBuffer* MC_NONNULL tx_out_confirmation_number,
                                            const McBuffer* MC_NONNULL view_private_key,
                                            bool* MC_NONNULL out_valid
                                            )
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_tx_out_get_value(
                         const McTxOutAmount* MC_NONNULL tx_out_amount,
                         const McBuffer* MC_NONNULL tx_out_public_key,
                         const McBuffer* MC_NONNULL view_private_key,
                         uint64_t* MC_NONNULL out_value,
                         McError* MC_NULLABLE * MC_NULLABLE out_error
                         )
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_tx_out_get_subaddress_spend_public_key(
                                               const McBuffer* MC_NONNULL tx_out_target_key,
                                               const McBuffer* MC_NONNULL tx_out_public_key,
                                               const McBuffer* MC_NONNULL view_private_key,
                                               McMutableBuffer* MC_NONNULL out_subaddress_spend_public_key,
                                               McError* MC_NULLABLE * MC_NULLABLE out_error
                                               )
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_tx_out_matches_subaddress(
                                  const McBuffer* MC_NONNULL tx_out_target_key,
                                  const McBuffer* MC_NONNULL tx_out_public_key,
                                  const McBuffer* MC_NONNULL view_private_key,
                                  const McBuffer* MC_NONNULL subaddress_spend_private_key,
                                  bool* MC_NONNULL out_matches
                                  )
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_account_key_get_public_address_fog_authority_sig(
                                                         const McAccountKey* MC_NONNULL account_key,
                                                         uint64_t subaddress_index,
                                                         McMutableBuffer* MC_NONNULL out_fog_authority_sig
                                                         )
{
    DDLogVerbose(@"Invalid method.");
}

void mc_error_free(McError* MC_NULLABLE error)
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_tx_out_matches_any_subaddress(
                                      const McTxOutAmount* MC_NONNULL tx_out_amount,
                                      const McBuffer* MC_NONNULL tx_out_public_key,
                                      const McBuffer* MC_NONNULL view_private_key,
                                      bool* MC_NONNULL out_matches
                                      )
{
    DDLogVerbose(@"Invalid method.");
}

ssize_t mc_printable_wrapper_b58_decode(
                                        const char* MC_NONNULL b58_encoded_string,
                                        McMutableBuffer* MC_NULLABLE out_printable_wrapper_proto_bytes,
                                        McError* MC_NULLABLE * MC_NULLABLE out_error
                                        )
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_ristretto_private_validate(
                                   const McBuffer* MC_NONNULL ristretto_private,
                                   bool* MC_NONNULL out_valid
                                   )
{
    DDLogVerbose(@"Invalid method.");
}

char* MC_NULLABLE mc_printable_wrapper_b58_encode(
                                                  const McBuffer* MC_NONNULL printable_wrapper_proto_bytes
                                                  )
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_account_key_get_public_address_public_keys(
                                                   const McBuffer* MC_NONNULL view_private_key,
                                                   const McBuffer* MC_NONNULL spend_private_key,
                                                   uint64_t subaddress_index,
                                                   McMutableBuffer* MC_NONNULL out_subaddress_view_public_key,
                                                   McMutableBuffer* MC_NONNULL out_subaddress_spend_public_key
                                                   )
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_ristretto_public_validate(
                                  const McBuffer* MC_NONNULL ristretto_public,
                                  bool* MC_NONNULL out_valid
                                  )
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_tx_out_get_key_image(
                             const McBuffer* MC_NONNULL tx_out_target_key,
                             const McBuffer* MC_NONNULL tx_out_public_key,
                             const McBuffer* MC_NONNULL view_private_key,
                             const McBuffer* MC_NONNULL subaddress_spend_private_key,
                             McMutableBuffer* MC_NONNULL out_key_image,
                             McError* MC_NULLABLE * MC_NULLABLE out_error
                             )
{
    DDLogVerbose(@"Invalid method.");
}

void mc_string_free(char* MC_NULLABLE string)
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_account_key_get_subaddress_private_keys(
                                                const McBuffer* MC_NONNULL view_private_key,
                                                const McBuffer* MC_NONNULL spend_private_key,
                                                uint64_t subaddress_index,
                                                McMutableBuffer* MC_NONNULL out_subaddress_view_private_key,
                                                McMutableBuffer* MC_NONNULL out_subaddress_spend_private_key
                                                )
{
    DDLogVerbose(@"Invalid method.");
}

ssize_t mc_bip39_entropy_from_mnemonic(
                                       const char* MC_NONNULL mnemonic,
                                       McMutableBuffer* MC_NULLABLE out_entropy,
                                       McError* MC_NULLABLE * MC_NULLABLE out_error
                                       )
{
    DDLogVerbose(@"Invalid method.");
}

char* MC_NULLABLE mc_bip39_words_by_prefix(
                                           const char* MC_NONNULL prefix
                                           )
{
    DDLogVerbose(@"Invalid method.");
}

char* MC_NULLABLE mc_bip39_mnemonic_from_entropy(
                                                 const McBuffer* MC_NONNULL entropy
                                                 )
{
    DDLogVerbose(@"Invalid method.");
}

void mc_transaction_builder_ring_free(
                                      McTransactionBuilderRing* MC_NULLABLE transaction_builder_ring
                                      )
{
    DDLogVerbose(@"Invalid method.");
}

McTransactionBuilderRing* MC_NULLABLE mc_transaction_builder_ring_create()
{
    DDLogVerbose(@"Invalid method.");
}

McData* MC_NULLABLE mc_transaction_builder_build(
                                                 McTransactionBuilder* MC_NONNULL transaction_builder,
                                                 McRngCallback* MC_NULLABLE rng_callback,
                                                 McError* MC_NULLABLE * MC_NULLABLE out_error
                                                 )
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_transaction_builder_add_input(
                                      McTransactionBuilder* MC_NONNULL transaction_builder,
                                      const McBuffer* MC_NONNULL view_private_key,
                                      const McBuffer* MC_NONNULL subaddress_spend_private_key,
                                      size_t real_index,
                                      const McTransactionBuilderRing* MC_NONNULL ring,
                                      McError* MC_NULLABLE * MC_NULLABLE out_error
                                      )
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_slip10_account_private_keys_from_mnemonic(
                                                  const char* MC_NONNULL mnemonic,
                                                  uint32_t account_index,
                                                  McMutableBuffer* MC_NONNULL out_view_private_key,
                                                  McMutableBuffer* MC_NONNULL out_spend_private_key,
                                                  McError* MC_NULLABLE * MC_NULLABLE out_error
                                                  )
{
    DDLogVerbose(@"Invalid method.");
}

ssize_t mc_data_get_bytes(
                          const McData* MC_NONNULL data,
                          McMutableBuffer* MC_NULLABLE out_bytes
                          )

{
    DDLogVerbose(@"Invalid method.");
}
void mc_transaction_builder_free(
                                 McTransactionBuilder* MC_NULLABLE transaction_builder
                                 )
{
    DDLogVerbose(@"Invalid method.");
}

void mc_fog_resolver_free(
                          McFogResolver* MC_NULLABLE fog_resolver
                          )
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_transaction_builder_ring_add_element(
                                             McTransactionBuilderRing* MC_NONNULL transaction_builder_ring,
                                             const McBuffer* MC_NONNULL tx_out_proto_bytes,
                                             const McBuffer* MC_NONNULL membership_proof_proto_bytes
                                             )
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_fog_resolver_add_report_response(
                                         McFogResolver* MC_NONNULL fog_resolver,
                                         const char* MC_NONNULL report_url,
                                         const McBuffer* MC_NONNULL report_response,
                                         McError* MC_NULLABLE * MC_NULLABLE out_error
                                         )
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_mr_signer_verifier_allow_hardening_advisory(
                                                    McMrSignerVerifier* MC_NONNULL mr_signer_verifier,
                                                    const char* MC_NONNULL advisory_id
                                                    )
{
    DDLogVerbose(@"Invalid method.");
}

McTransactionBuilder* MC_NULLABLE mc_transaction_builder_create(
                                                                uint64_t fee,
                                                                uint64_t tombstone_block,
                                                                const McFogResolver* MC_NULLABLE fog_resolver
                                                                )
{
    DDLogVerbose(@"Invalid method.");
}

void mc_mr_enclave_verifier_free(
                                 McMrEnclaveVerifier* MC_NULLABLE mr_enclave_verifier
                                 )
{
    DDLogVerbose(@"Invalid method.");
}

void mc_data_free(McData* MC_NULLABLE data)
{
    DDLogVerbose(@"Invalid method.");
}

void mc_verifier_free(
                      McVerifier* MC_NULLABLE verifier
                      )
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_mr_signer_verifier_allow_config_advisory(
                                                 McMrSignerVerifier* MC_NONNULL mr_signer_verifier,
                                                 const char* MC_NONNULL advisory_id
                                                 )
{
    DDLogVerbose(@"Invalid method.");
}

void mc_mr_signer_verifier_free(
                                McMrSignerVerifier* MC_NULLABLE mr_signer_verifier
                                )
{
    DDLogVerbose(@"Invalid method.");
}

McFogResolver* MC_NULLABLE mc_fog_resolver_create(
                                                  const McVerifier* MC_NONNULL fog_report_verifier
                                                  )
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_mr_enclave_verifier_allow_hardening_advisory(
                                                     McMrEnclaveVerifier* MC_NONNULL mr_enclave_verifier,
                                                     const char* MC_NONNULL advisory_id
                                                     )
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_mr_enclave_verifier_allow_config_advisory(
                                                  McMrEnclaveVerifier* MC_NONNULL mr_enclave_verifier,
                                                  const char* MC_NONNULL advisory_id
                                                  )
{
    DDLogVerbose(@"Invalid method.");
}

McMrSignerVerifier* MC_NULLABLE mc_mr_signer_verifier_create(
                                                             const McBuffer* MC_NONNULL mr_signer,
                                                             uint16_t expected_product_id,
                                                             uint16_t minimum_security_version
                                                             )
{
    DDLogVerbose(@"Invalid method.");
}

McVerifier* MC_NULLABLE mc_verifier_create()
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_verifier_add_mr_signer(
                               McVerifier* MC_NONNULL verifier,
                               const McMrSignerVerifier* MC_NONNULL mr_signer_verifier
                               )
{
    DDLogVerbose(@"Invalid method.");
}

McData* MC_NULLABLE mc_transaction_builder_add_output(
                                                      McTransactionBuilder* MC_NONNULL transaction_builder,
                                                      uint64_t amount,
                                                      const McPublicAddress* MC_NONNULL recipient_address,
                                                      McRngCallback* MC_NULLABLE rng_callback,
                                                      McMutableBuffer* MC_NONNULL out_tx_out_confirmation_number,
                                                      McError* MC_NULLABLE * MC_NULLABLE out_error
                                                      )
{
    DDLogVerbose(@"Invalid method.");
}

bool mc_verifier_add_mr_enclave(
                                McVerifier* MC_NONNULL verifier,
                                const McMrEnclaveVerifier* MC_NONNULL mr_enclave_verifier
                                )
{
    DDLogVerbose(@"Invalid method.");
}

McMrEnclaveVerifier* MC_NULLABLE mc_mr_enclave_verifier_create(
                                                               const McBuffer* MC_NONNULL mr_enclave
                                                               )
{
    DDLogVerbose(@"Invalid method.");
}
