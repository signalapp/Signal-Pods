#ifndef BIP39_H_
#define BIP39_H_

#include "common.h"

/* ==================== BIP39 ==================== */

#ifdef __cplusplus
extern "C" {
#endif

/* ==== McBip39 ==== */

/// # Preconditions
///
/// * `mnemonic` - must be a nul-terminated C string containing valid UTF-8.
/// * `out_entropy` - must be null or else length must be >= `entropy.len`.
///
/// # Errors
///
/// * `LibMcError::InvalidInput`
ssize_t mc_bip39_entropy_from_mnemonic(
  const char* MC_NONNULL mnemonic,
  McMutableBuffer* MC_NULLABLE out_entropy,
  McError* MC_NULLABLE * MC_NULLABLE out_error
)
MC_ATTRIBUTE_NONNULL(1);

/// # Preconditions
///
/// * `entropy` - length must be a multiple of 4 and between 16 and 32, inclusive.
char* MC_NULLABLE mc_bip39_entropy_to_mnemonic(
  const McBuffer* MC_NONNULL entropy
)
MC_ATTRIBUTE_NONNULL(1);

/// # Preconditions
///
/// * `mnemonic` - must be a nul-terminated C string containing valid UTF-8.
/// * `passphrase` - must be a nul-terminated C string containing valid UTF-8. Can be empty.
/// * `out_seed` - length must be >= 64.
///
/// # Errors
///
/// * `LibMcError::InvalidInput`
bool mc_bip39_get_seed(
  const char* MC_NONNULL mnemonic,
  const char* MC_NONNULL  passphrase,
  McMutableBuffer* MC_NONNULL out_seed,
  McError* MC_NULLABLE * MC_NULLABLE out_error
)
MC_ATTRIBUTE_NONNULL(1, 2, 3);

/// # Preconditions
///
/// * `prefix` - must be a nul-terminated C string containing valid UTF-8.
char* MC_NULLABLE mc_bip39_words_by_prefix(
  const char* MC_NONNULL prefix
)
MC_ATTRIBUTE_NONNULL(1);


#ifdef __cplusplus
}
#endif

#endif /* !BIP39_H_ */
