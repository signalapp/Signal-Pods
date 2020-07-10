#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#define AESGCM_NONCE_LEN 12

#define AESGCM_TAG_LEN 16

#define AES_KEY_LEN 32

#define AUTH_CREDENTIAL_LEN 342

#define AUTH_CREDENTIAL_PRESENTATION_LEN 493

#define AUTH_CREDENTIAL_RESPONSE_LEN 361

#define FFI_RETURN_INPUT_ERROR 2

#define FFI_RETURN_INTERNAL_ERROR 1

#define FFI_RETURN_OK 0

#define GROUP_IDENTIFIER_LEN 32

#define GROUP_MASTER_KEY_LEN 32

#define GROUP_PUBLIC_PARAMS_LEN 97

#define GROUP_SECRET_PARAMS_LEN 289

#define NUM_AUTH_CRED_ATTRIBUTES 3

#define NUM_PROFILE_KEY_CRED_ATTRIBUTES 4

#define PROFILE_KEY_CIPHERTEXT_LEN 65

#define PROFILE_KEY_COMMITMENT_LEN 97

#define PROFILE_KEY_CREDENTIAL_LEN 145

#define PROFILE_KEY_CREDENTIAL_PRESENTATION_LEN 713

#define PROFILE_KEY_CREDENTIAL_REQUEST_CONTEXT_LEN 473

#define PROFILE_KEY_CREDENTIAL_REQUEST_LEN 329

#define PROFILE_KEY_CREDENTIAL_RESPONSE_LEN 457

#define PROFILE_KEY_LEN 32

#define PROFILE_KEY_VERSION_ENCODED_LEN 64

#define PROFILE_KEY_VERSION_LEN 32

#define RANDOMNESS_LEN 32

#define RESERVED_LEN 1

#define SERVER_PUBLIC_PARAMS_LEN 161

#define SERVER_SECRET_PARAMS_LEN 769

#define SIGNATURE_LEN 64

#define UUID_CIPHERTEXT_LEN 65

#define UUID_LEN 16

int32_t FFI_AuthCredentialPresentation_checkValidContents(const uint8_t *authCredentialPresentation,
                                                          uint32_t authCredentialPresentationLen);

int32_t FFI_AuthCredentialPresentation_getRedemptionTime(const uint8_t *authCredentialPresentation,
                                                         uint32_t authCredentialPresentationLen,
                                                         uint8_t *redemptionTimeOut,
                                                         uint32_t redemptionTimeLen);

int32_t FFI_AuthCredentialPresentation_getUuidCiphertext(const uint8_t *authCredentialPresentation,
                                                         uint32_t authCredentialPresentationLen,
                                                         uint8_t *uuidCiphertextOut,
                                                         uint32_t uuidCiphertextLen);

int32_t FFI_AuthCredentialResponse_checkValidContents(const uint8_t *authCredentialResponse,
                                                      uint32_t authCredentialResponseLen);

int32_t FFI_AuthCredential_checkValidContents(const uint8_t *authCredential,
                                              uint32_t authCredentialLen);

int32_t FFI_GroupPublicParams_checkValidContents(const uint8_t *groupPublicParams,
                                                 uint32_t groupPublicParamsLen);

int32_t FFI_GroupPublicParams_getGroupIdentifier(const uint8_t *groupPublicParams,
                                                 uint32_t groupPublicParamsLen,
                                                 uint8_t *groupIdentifierOut,
                                                 uint32_t groupIdentifierLen);

int32_t FFI_GroupSecretParams_checkValidContents(const uint8_t *groupSecretParams,
                                                 uint32_t groupSecretParamsLen);

int32_t FFI_GroupSecretParams_decryptBlob(const uint8_t *groupSecretParams,
                                          uint32_t groupSecretParamsLen,
                                          const uint8_t *blobCiphertext,
                                          uint32_t blobCiphertextLen,
                                          uint8_t *plaintextOut,
                                          uint32_t plaintextLen);

int32_t FFI_GroupSecretParams_decryptProfileKey(const uint8_t *groupSecretParams,
                                                uint32_t groupSecretParamsLen,
                                                const uint8_t *profileKeyCiphertext,
                                                uint32_t profileKeyCiphertextLen,
                                                const uint8_t *uuid,
                                                uint32_t uuidLen,
                                                uint8_t *profileKeyOut,
                                                uint32_t profileKeyLen);

int32_t FFI_GroupSecretParams_decryptUuid(const uint8_t *groupSecretParams,
                                          uint32_t groupSecretParamsLen,
                                          const uint8_t *uuidCiphertext,
                                          uint32_t uuidCiphertextLen,
                                          uint8_t *uuidOut,
                                          uint32_t uuidLen);

int32_t FFI_GroupSecretParams_deriveFromMasterKey(const uint8_t *groupMasterKey,
                                                  uint32_t groupMasterKeyLen,
                                                  uint8_t *groupSecretParamsOut,
                                                  uint32_t groupSecretParamsLen);

int32_t FFI_GroupSecretParams_encryptBlobDeterministic(const uint8_t *groupSecretParams,
                                                       uint32_t groupSecretParamsLen,
                                                       const uint8_t *randomness,
                                                       uint32_t randomnessLen,
                                                       const uint8_t *plaintext,
                                                       uint32_t plaintextLen,
                                                       uint8_t *blobCiphertextOut,
                                                       uint32_t blobCiphertextLen);

int32_t FFI_GroupSecretParams_encryptProfileKey(const uint8_t *groupSecretParams,
                                                uint32_t groupSecretParamsLen,
                                                const uint8_t *profileKey,
                                                uint32_t profileKeyLen,
                                                const uint8_t *uuid,
                                                uint32_t uuidLen,
                                                uint8_t *profileKeyCiphertextOut,
                                                uint32_t profileKeyCiphertextLen);

int32_t FFI_GroupSecretParams_encryptUuid(const uint8_t *groupSecretParams,
                                          uint32_t groupSecretParamsLen,
                                          const uint8_t *uuid,
                                          uint32_t uuidLen,
                                          uint8_t *uuidCiphertextOut,
                                          uint32_t uuidCiphertextLen);

int32_t FFI_GroupSecretParams_generateDeterministic(const uint8_t *randomness,
                                                    uint32_t randomnessLen,
                                                    uint8_t *groupSecretParamsOut,
                                                    uint32_t groupSecretParamsLen);

int32_t FFI_GroupSecretParams_getMasterKey(const uint8_t *groupSecretParams,
                                           uint32_t groupSecretParamsLen,
                                           uint8_t *groupMasterKeyOut,
                                           uint32_t groupMasterKeyLen);

int32_t FFI_GroupSecretParams_getPublicParams(const uint8_t *groupSecretParams,
                                              uint32_t groupSecretParamsLen,
                                              uint8_t *groupPublicParamsOut,
                                              uint32_t groupPublicParamsLen);

int32_t FFI_ProfileKeyCiphertext_checkValidContents(const uint8_t *profileKeyCiphertext,
                                                    uint32_t profileKeyCiphertextLen);

int32_t FFI_ProfileKeyCommitment_checkValidContents(const uint8_t *profileKeyCommitment,
                                                    uint32_t profileKeyCommitmentLen);

int32_t FFI_ProfileKeyCredentialPresentation_checkValidContents(const uint8_t *profileKeyCredentialPresentation,
                                                                uint32_t profileKeyCredentialPresentationLen);

int32_t FFI_ProfileKeyCredentialPresentation_getProfileKeyCiphertext(const uint8_t *profileKeyCredentialPresentation,
                                                                     uint32_t profileKeyCredentialPresentationLen,
                                                                     uint8_t *profileKeyCiphertextOut,
                                                                     uint32_t profileKeyCiphertextLen);

int32_t FFI_ProfileKeyCredentialPresentation_getUuidCiphertext(const uint8_t *profileKeyCredentialPresentation,
                                                               uint32_t profileKeyCredentialPresentationLen,
                                                               uint8_t *uuidCiphertextOut,
                                                               uint32_t uuidCiphertextLen);

int32_t FFI_ProfileKeyCredentialRequestContext_checkValidContents(const uint8_t *profileKeyCredentialRequestContext,
                                                                  uint32_t profileKeyCredentialRequestContextLen);

int32_t FFI_ProfileKeyCredentialRequestContext_getRequest(const uint8_t *profileKeyCredentialRequestContext,
                                                          uint32_t profileKeyCredentialRequestContextLen,
                                                          uint8_t *profileKeyCredentialRequestOut,
                                                          uint32_t profileKeyCredentialRequestLen);

int32_t FFI_ProfileKeyCredentialRequest_checkValidContents(const uint8_t *profileKeyCredentialRequest,
                                                           uint32_t profileKeyCredentialRequestLen);

int32_t FFI_ProfileKeyCredentialResponse_checkValidContents(const uint8_t *profileKeyCredentialResponse,
                                                            uint32_t profileKeyCredentialResponseLen);

int32_t FFI_ProfileKeyCredential_checkValidContents(const uint8_t *profileKeyCredential,
                                                    uint32_t profileKeyCredentialLen);

int32_t FFI_ProfileKey_getCommitment(const uint8_t *profileKey,
                                     uint32_t profileKeyLen,
                                     const uint8_t *uuid,
                                     uint32_t uuidLen,
                                     uint8_t *profileKeyCommitmentOut,
                                     uint32_t profileKeyCommitmentLen);

int32_t FFI_ProfileKey_getProfileKeyVersion(const uint8_t *profileKey,
                                            uint32_t profileKeyLen,
                                            const uint8_t *uuid,
                                            uint32_t uuidLen,
                                            uint8_t *profileKeyVersionOut,
                                            uint32_t profileKeyVersionLen);

int32_t FFI_Randomness_checkValidContents(const uint8_t *randomness, uint32_t randomnessLen);

int32_t FFI_ServerPublicParams_checkValidContents(const uint8_t *serverPublicParams,
                                                  uint32_t serverPublicParamsLen);

int32_t FFI_ServerPublicParams_createAuthCredentialPresentationDeterministic(const uint8_t *serverPublicParams,
                                                                             uint32_t serverPublicParamsLen,
                                                                             const uint8_t *randomness,
                                                                             uint32_t randomnessLen,
                                                                             const uint8_t *groupSecretParams,
                                                                             uint32_t groupSecretParamsLen,
                                                                             const uint8_t *authCredential,
                                                                             uint32_t authCredentialLen,
                                                                             uint8_t *authCredentialPresentationOut,
                                                                             uint32_t authCredentialPresentationLen);

int32_t FFI_ServerPublicParams_createProfileKeyCredentialPresentationDeterministic(const uint8_t *serverPublicParams,
                                                                                   uint32_t serverPublicParamsLen,
                                                                                   const uint8_t *randomness,
                                                                                   uint32_t randomnessLen,
                                                                                   const uint8_t *groupSecretParams,
                                                                                   uint32_t groupSecretParamsLen,
                                                                                   const uint8_t *profileKeyCredential,
                                                                                   uint32_t profileKeyCredentialLen,
                                                                                   uint8_t *profileKeyCredentialPresentationOut,
                                                                                   uint32_t profileKeyCredentialPresentationLen);

int32_t FFI_ServerPublicParams_createProfileKeyCredentialRequestContextDeterministic(const uint8_t *serverPublicParams,
                                                                                     uint32_t serverPublicParamsLen,
                                                                                     const uint8_t *randomness,
                                                                                     uint32_t randomnessLen,
                                                                                     const uint8_t *uuid,
                                                                                     uint32_t uuidLen,
                                                                                     const uint8_t *profileKey,
                                                                                     uint32_t profileKeyLen,
                                                                                     uint8_t *profileKeyCredentialRequestContextOut,
                                                                                     uint32_t profileKeyCredentialRequestContextLen);

int32_t FFI_ServerPublicParams_receiveAuthCredential(const uint8_t *serverPublicParams,
                                                     uint32_t serverPublicParamsLen,
                                                     const uint8_t *uuid,
                                                     uint32_t uuidLen,
                                                     uint32_t redemptionTime,
                                                     const uint8_t *authCredentialResponse,
                                                     uint32_t authCredentialResponseLen,
                                                     uint8_t *authCredentialOut,
                                                     uint32_t authCredentialLen);

int32_t FFI_ServerPublicParams_receiveProfileKeyCredential(const uint8_t *serverPublicParams,
                                                           uint32_t serverPublicParamsLen,
                                                           const uint8_t *profileKeyCredentialRequestContext,
                                                           uint32_t profileKeyCredentialRequestContextLen,
                                                           const uint8_t *profileKeyCredentialResponse,
                                                           uint32_t profileKeyCredentialResponseLen,
                                                           uint8_t *profileKeyCredentialOut,
                                                           uint32_t profileKeyCredentialLen);

int32_t FFI_ServerPublicParams_verifySignature(const uint8_t *serverPublicParams,
                                               uint32_t serverPublicParamsLen,
                                               const uint8_t *message,
                                               uint32_t messageLen,
                                               const uint8_t *notarySignature,
                                               uint32_t notarySignatureLen);

int32_t FFI_ServerSecretParams_checkValidContents(const uint8_t *serverSecretParams,
                                                  uint32_t serverSecretParamsLen);

int32_t FFI_ServerSecretParams_generateDeterministic(const uint8_t *randomness,
                                                     uint32_t randomnessLen,
                                                     uint8_t *serverSecretParamsOut,
                                                     uint32_t serverSecretParamsLen);

int32_t FFI_ServerSecretParams_getPublicParams(const uint8_t *serverSecretParams,
                                               uint32_t serverSecretParamsLen,
                                               uint8_t *serverPublicParamsOut,
                                               uint32_t serverPublicParamsLen);

int32_t FFI_ServerSecretParams_issueAuthCredentialDeterministic(const uint8_t *serverSecretParams,
                                                                uint32_t serverSecretParamsLen,
                                                                const uint8_t *randomness,
                                                                uint32_t randomnessLen,
                                                                const uint8_t *uuid,
                                                                uint32_t uuidLen,
                                                                uint32_t redemptionTime,
                                                                uint8_t *authCredentialResponseOut,
                                                                uint32_t authCredentialResponseLen);

int32_t FFI_ServerSecretParams_issueProfileKeyCredentialDeterministic(const uint8_t *serverSecretParams,
                                                                      uint32_t serverSecretParamsLen,
                                                                      const uint8_t *randomness,
                                                                      uint32_t randomnessLen,
                                                                      const uint8_t *profileKeyCredentialRequest,
                                                                      uint32_t profileKeyCredentialRequestLen,
                                                                      const uint8_t *uuid,
                                                                      uint32_t uuidLen,
                                                                      const uint8_t *profileKeyCommitment,
                                                                      uint32_t profileKeyCommitmentLen,
                                                                      uint8_t *profileKeyCredentialResponseOut,
                                                                      uint32_t profileKeyCredentialResponseLen);

int32_t FFI_ServerSecretParams_signDeterministic(const uint8_t *serverSecretParams,
                                                 uint32_t serverSecretParamsLen,
                                                 const uint8_t *randomness,
                                                 uint32_t randomnessLen,
                                                 const uint8_t *message,
                                                 uint32_t messageLen,
                                                 uint8_t *notarySignatureOut,
                                                 uint32_t notarySignatureLen);

int32_t FFI_ServerSecretParams_verifyAuthCredentialPresentation(const uint8_t *serverSecretParams,
                                                                uint32_t serverSecretParamsLen,
                                                                const uint8_t *groupPublicParams,
                                                                uint32_t groupPublicParamsLen,
                                                                const uint8_t *authCredentialPresentation,
                                                                uint32_t authCredentialPresentationLen);

int32_t FFI_ServerSecretParams_verifyProfileKeyCredentialPresentation(const uint8_t *serverSecretParams,
                                                                      uint32_t serverSecretParamsLen,
                                                                      const uint8_t *groupPublicParams,
                                                                      uint32_t groupPublicParamsLen,
                                                                      const uint8_t *profileKeyCredentialPresentation,
                                                                      uint32_t profileKeyCredentialPresentationLen);

int32_t FFI_UuidCiphertext_checkValidContents(const uint8_t *uuidCiphertext,
                                              uint32_t uuidCiphertextLen);

int32_t FFI_Uuid_checkValidContents(const uint8_t *uuid, uint32_t uuidLen);
