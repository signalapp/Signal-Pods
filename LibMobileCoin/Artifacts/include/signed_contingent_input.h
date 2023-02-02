// Copyright (c) 2018-2022 The MobileCoin Foundation

#ifndef SIGNED_CONTINGENT_INPUT_H_
#define SIGNED_CONTINGENT_INPUT_H_

#include "common.h"
#include "fog.h"
#include "keys.h"

/* ==================== Signed Contingent Input ==================== */

#ifdef __cplusplus
extern "C" {
#endif

/* ==== Types ==== */

typedef struct _McSignedContingentInputBuilder McSignedContingentInputBuilder;
typedef struct _McTxOutMemoBuilder McTxOutMemoBuilder;
typedef struct _McTransactionBuilderRing McTransactionBuilderRing;

/* ==== McSignedContingentInputBuilder ==== */

/// # Preconditions
///
///
/// * `view_private_key` - must be a valid 32-byte Ristretto-format scalar.
/// * `subaddress_spend_private_key` - must be a valid 32-byte Ristretto-format scalar.
/// * `real_index` - must be within bounds of `ring`.
/// * `ring` - `TxOut` at `real_index` must be owned by account keys.
///
/// # Errors
///
/// * `LibMcError::InvalidInput`
McSignedContingentInputBuilder* MC_NULLABLE mc_signed_contingent_input_builder_create(
  uint32_t block_version,
  uint64_t tombstone_block,
  const McFogResolver* MC_NULLABLE fog_resolver,
  McTxOutMemoBuilder* MC_NONNULL memo_builder,
  const McBuffer* MC_NONNULL view_private_key,
  const McBuffer* MC_NONNULL subaddress_spend_private_key,
  size_t real_index,
  const McTransactionBuilderRing* MC_NONNULL ring,
  McError* MC_NULLABLE * MC_NULLABLE out_error
)
MC_ATTRIBUTE_NONNULL(4,5,6,8);

void mc_signed_contingent_input_builder_free(
  McSignedContingentInputBuilder* MC_NULLABLE signed_contingent_input_builder
);

/// # Preconditions
///
/// * `signed_contingent_input_builder` - must not have been previously consumed by a call to `build`.
/// * `recipient_address` - must be a valid `PublicAddress`.
/// * `out_subaddress_spend_public_key` - length must be >= 32.
///
/// # Errors
///
/// * `LibMcError::AttestationVerification`
/// * `LibMcError::InvalidInput`
McData* MC_NULLABLE mc_signed_contingent_input_builder_add_required_output(
  McSignedContingentInputBuilder* MC_NONNULL signed_contingent_input_builder,
  uint64_t amount,
  uint64_t token_id,
  const McPublicAddress* MC_NONNULL recipient_address,
  McRngCallback* MC_NULLABLE rng_callback,
  McMutableBuffer* MC_NONNULL out_tx_out_confirmation_number,
  McError* MC_NULLABLE * MC_NULLABLE out_error
)
MC_ATTRIBUTE_NONNULL(1, 4, 6);

/// # Preconditions
///
/// * `account_kay` - must be a valid account key, default change address computed from account key
/// * `signed_contingent_input_builder` - must not have been previously consumed by a call
///   to `build`.
/// * `out_tx_out_confirmation_number` - length must be >= 32.
///
/// # Errors
///
/// * `LibMcError::AttestationVerification`
/// * `LibMcError::InvalidInput`
McData* MC_NULLABLE mc_signed_contingent_input_builder_add_required_change_output(
  const McAccountKey* MC_NONNULL account_key,
  McSignedContingentInputBuilder* MC_NONNULL signed_contingent_input_builder,
  uint64_t amount,
  uint64_t token_id,
  McRngCallback* MC_NULLABLE rng_callback,
  McMutableBuffer* MC_NONNULL out_tx_out_confirmation_number,
  McError* MC_NULLABLE * MC_NULLABLE out_error
)
MC_ATTRIBUTE_NONNULL(1, 2, 6);

/// # Preconditions
///
/// * `signed_contingent_input_builder` - must not have been previously consumed by a call to `build`.
///
/// # Errors
///
/// * `LibMcError::InvalidInput`
McData* MC_NULLABLE mc_signed_contingent_input_builder_build(
  McSignedContingentInputBuilder* MC_NONNULL signed_contingent_input_builder,
  McRngCallback* MC_NULLABLE rng_callback,
  const McTransactionBuilderRing* MC_NONNULL ring,
  McError* MC_NULLABLE * MC_NULLABLE out_error
)
MC_ATTRIBUTE_NONNULL(1);

// #[no_mangle]
// pub extern "C" fn mc_signed_contingent_input_data_is_valid(
//     sci_data: FfiRefPtr<McBuffer>,
//     out_valid: FfiMutPtr<bool>,
//     out_error: FfiOptMutPtr<FfiOptOwnedPtr<McError>>,
// ) -> bool {
bool mc_signed_contingent_input_data_is_valid(
  const McBuffer* MC_NONNULL signed_contingent_input,
  McError* MC_NULLABLE * MC_NULLABLE out_error
)
MC_ATTRIBUTE_NONNULL(1);


#ifdef __cplusplus
}
#endif

#endif /* !SIGNED_CONTINGENT_INPUT_H_ */
