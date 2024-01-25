// Copyright (c) 2018-2023 The MobileCoin Foundation

#ifndef BLOCKCHAIN_TYPES_H_
#define BLOCKCHAIN_TYPES_H_

#include "common.h"

#ifdef __cplusplus
extern "C"
{
#endif

/* ==================== BlockData ==================== */
typedef struct _McBlockData McBlockData;

McBlockData *MC_NULLABLE mc_block_data_from_archive_block_protobuf(
    const McBuffer *MC_NONNULL archive_block_protobuf,
    McError *MC_NULLABLE *MC_NULLABLE out_error)
    MC_ATTRIBUTE_NONNULL(1);

void mc_block_data_free(McBlockData *MC_NONNULL block_data)
    MC_ATTRIBUTE_NONNULL(1);

/* ==================== BlockDataVec ==================== */

typedef struct _McBlockDataVec McBlockDataVec;

McBlockDataVec *MC_NULLABLE mc_block_data_vec_create(void);

void mc_block_data_vec_free(
    McBlockDataVec *MC_NONNULL block_data_vec) MC_ATTRIBUTE_NONNULL(1);

bool
mc_block_data_vec_add_element(McBlockDataVec *MC_NONNULL block_data_vec,
                              McBlockData *MC_NONNULL block_data) MC_ATTRIBUTE_NONNULL(1, 2);

#ifdef __cplusplus
}
#endif

#endif /* !BLOCKCHAIN_TYPES_H_ */
