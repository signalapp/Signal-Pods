#ifndef SLIP10_H_
#define SLIP10_H_

#include "common.h"

/* ==================== SLIP10 ==================== */

#ifdef __cplusplus
extern "C" {
#endif

/* ==== Types ==== */

typedef struct _McSlip10Indices McSlip10Indices;

/* ==== McSlip10Indices ==== */

McSlip10Indices* MC_NULLABLE mc_slip10_indices_create(void);

void mc_slip10_indices_free(
  McSlip10Indices* MC_NULLABLE indices
);

bool mc_slip10_indices_add(
  McSlip10Indices* MC_NONNULL indices,
  uint32_t index
)
MC_ATTRIBUTE_NONNULL(1);

/* ==== McSlip10 ==== */

/// # Preconditions
///
/// * `out_key` - length must be >= 32.
bool mc_slip10_derive_ed25519_private_key(
  const McBuffer* MC_NONNULL seed,
  const McSlip10Indices* MC_NONNULL path,
  McMutableBuffer* MC_NONNULL out_key
)
MC_ATTRIBUTE_NONNULL(1, 2, 3);

#ifdef __cplusplus
}
#endif

#endif /* !SLIP10_H_ */
