#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#define AUTH_CREDENTIAL_LEN 404

#define AUTH_CREDENTIAL_PRESENTATION_LEN 620

#define AUTH_CREDENTIAL_RESPONSE_LEN 392

#define CLIENT_CREDENTIAL_MANAGER_LEN 256

#define FFI_RETURN_INPUT_ERROR 2

#define FFI_RETURN_INTERNAL_ERROR 1

#define FFI_RETURN_OK 0

#define GROUP_IDENTIFIER_LEN 32

#define GROUP_MASTER_KEY_LEN 32

#define GROUP_PUBLIC_PARAMS_LEN 128

#define GROUP_SECRET_PARAMS_LEN 384

#define NUM_AUTH_CRED_ATTRIBUTES 4

#define NUM_PROFILE_KEY_CRED_ATTRIBUTES 6

#define PROFILE_KEY_CIPHERTEXT_LEN 64

#define PROFILE_KEY_COMMITMENT_LEN 96

#define PROFILE_KEY_CREDENTIAL_LEN 144

#define PROFILE_KEY_CREDENTIAL_PRESENTATION_LEN 936

#define PROFILE_KEY_CREDENTIAL_REQUEST_CONTEXT_LEN 600

#define PROFILE_KEY_CREDENTIAL_REQUEST_LEN 424

#define PROFILE_KEY_CREDENTIAL_RESPONSE_LEN 520

#define PROFILE_KEY_LEN 32

#define PROFILE_KEY_VERSION_ENCODED_LEN 64

#define PROFILE_KEY_VERSION_LEN 32

#define RANDOMNESS_LEN 32

#define SERVER_PUBLIC_PARAMS_LEN 160

#define SERVER_SECRET_PARAMS_LEN 896

#define SIGNATURE_LEN 64

#define UUID_CIPHERTEXT_LEN 64

#define UUID_LEN 16

int32_t FFI_AuthCredentialPresentation_checkValidContents(const uint8_t *authCredentialPresentation,
                                                          uint64_t authCredentialPresentationLen);

int32_t FFI_AuthCredentialPresentation_getRedemptionTime(const uint8_t *authCredentialPresentation,
                                                         uint64_t authCredentialPresentationLen,
                                                         uint8_t *redemptionTimeOut,
                                                         uint64_t redemptionTimeLen);

int32_t FFI_AuthCredentialPresentation_getUuidCiphertext(const uint8_t *authCredentialPresentation,
                                                         uint64_t authCredentialPresentationLen,
                                                         uint8_t *uuidCiphertextOut,
                                                         uint64_t uuidCiphertextLen);

int32_t FFI_AuthCredentialResponse_checkValidContents(const uint8_t *authCredentialResponse,
                                                      uint64_t authCredentialResponseLen);

int32_t FFI_AuthCredential_checkValidContents(const uint8_t *authCredential,
                                              uint64_t authCredentialLen);

int32_t FFI_GroupPublicParams_checkValidContents(const uint8_t *groupPublicParams,
                                                 uint64_t groupPublicParamsLen);

int32_t FFI_GroupPublicParams_getGroupIdentifier(const uint8_t *groupPublicParams,
                                                 uint64_t groupPublicParamsLen,
                                                 uint8_t *groupIdentifierOut,
                                                 uint64_t groupIdentifierLen);

int32_t FFI_GroupPublicParams_verifySignature(const uint8_t *groupPublicParams,
                                              uint64_t groupPublicParamsLen,
                                              const uint8_t *message,
                                              uint64_t messageLen,
                                              const uint8_t *changeSignature,
                                              uint64_t changeSignatureLen);

int32_t FFI_GroupSecretParams_checkValidContents(const uint8_t *groupSecretParams,
                                                 uint64_t groupSecretParamsLen);

int32_t FFI_GroupSecretParams_decryptBlob(const uint8_t *groupSecretParams,
                                          uint64_t groupSecretParamsLen,
                                          const uint8_t *blobCiphertext,
                                          uint64_t blobCiphertextLen,
                                          uint8_t *plaintextOut,
                                          uint64_t plaintextLen);

int32_t FFI_GroupSecretParams_decryptProfileKey(const uint8_t *groupSecretParams,
                                                uint64_t groupSecretParamsLen,
                                                const uint8_t *profileKeyCiphertext,
                                                uint64_t profileKeyCiphertextLen,
                                                const uint8_t *uuid,
                                                uint64_t uuidLen,
                                                uint8_t *profileKeyOut,
                                                uint64_t profileKeyLen);

int32_t FFI_GroupSecretParams_decryptUuid(const uint8_t *groupSecretParams,
                                          uint64_t groupSecretParamsLen,
                                          const uint8_t *uuidCiphertext,
                                          uint64_t uuidCiphertextLen,
                                          uint8_t *uuidOut,
                                          uint64_t uuidLen);

int32_t FFI_GroupSecretParams_deriveFromMasterKey(const uint8_t *groupMasterKey,
                                                  uint64_t groupMasterKeyLen,
                                                  uint8_t *groupSecretParamsOut,
                                                  uint64_t groupSecretParamsLen);

int32_t FFI_GroupSecretParams_encryptBlobDeterministic(const uint8_t *groupSecretParams,
                                                       uint64_t groupSecretParamsLen,
                                                       const uint8_t *randomness,
                                                       uint64_t randomnessLen,
                                                       const uint8_t *plaintext,
                                                       uint64_t plaintextLen,
                                                       uint8_t *blobCiphertextOut,
                                                       uint64_t blobCiphertextLen);

int32_t FFI_GroupSecretParams_encryptProfileKeyDeterministic(const uint8_t *groupSecretParams,
                                                             uint64_t groupSecretParamsLen,
                                                             const uint8_t *randomness,
                                                             uint64_t randomnessLen,
                                                             const uint8_t *profileKey,
                                                             uint64_t profileKeyLen,
                                                             const uint8_t *uuid,
                                                             uint64_t uuidLen,
                                                             uint8_t *profileKeyCiphertextOut,
                                                             uint64_t profileKeyCiphertextLen);

int32_t FFI_GroupSecretParams_encryptUuid(const uint8_t *groupSecretParams,
                                          uint64_t groupSecretParamsLen,
                                          const uint8_t *uuid,
                                          uint64_t uuidLen,
                                          uint8_t *uuidCiphertextOut,
                                          uint64_t uuidCiphertextLen);

int32_t FFI_GroupSecretParams_generateDeterministic(const uint8_t *randomness,
                                                    uint64_t randomnessLen,
                                                    uint8_t *groupSecretParamsOut,
                                                    uint64_t groupSecretParamsLen);

int32_t FFI_GroupSecretParams_getMasterKey(const uint8_t *groupSecretParams,
                                           uint64_t groupSecretParamsLen,
                                           uint8_t *groupMasterKeyOut,
                                           uint64_t groupMasterKeyLen);

int32_t FFI_GroupSecretParams_getPublicParams(const uint8_t *groupSecretParams,
                                              uint64_t groupSecretParamsLen,
                                              uint8_t *groupPublicParamsOut,
                                              uint64_t groupPublicParamsLen);

int32_t FFI_GroupSecretParams_signDeterministic(const uint8_t *groupSecretParams,
                                                uint64_t groupSecretParamsLen,
                                                const uint8_t *randomness,
                                                uint64_t randomnessLen,
                                                const uint8_t *message,
                                                uint64_t messageLen,
                                                uint8_t *changeSignatureOut,
                                                uint64_t changeSignatureLen);

int32_t FFI_ProfileKeyCiphertext_checkValidContents(const uint8_t *profileKeyCiphertext,
                                                    uint64_t profileKeyCiphertextLen);

int32_t FFI_ProfileKeyCommitment_checkValidContents(const uint8_t *profileKeyCommitment,
                                                    uint64_t profileKeyCommitmentLen);

int32_t FFI_ProfileKeyCommitment_getProfileKeyVersion(const uint8_t *profileKeyCommitment,
                                                      uint64_t profileKeyCommitmentLen,
                                                      uint8_t *profileKeyVersionOut,
                                                      uint64_t profileKeyVersionLen);

int32_t FFI_ProfileKeyCredentialPresentation_checkValidContents(const uint8_t *profileKeyCredentialPresentation,
                                                                uint64_t profileKeyCredentialPresentationLen);

int32_t FFI_ProfileKeyCredentialPresentation_getProfileKeyCiphertext(const uint8_t *profileKeyCredentialPresentation,
                                                                     uint64_t profileKeyCredentialPresentationLen,
                                                                     uint8_t *profileKeyCiphertextOut,
                                                                     uint64_t profileKeyCiphertextLen);

int32_t FFI_ProfileKeyCredentialPresentation_getUuidCiphertext(const uint8_t *profileKeyCredentialPresentation,
                                                               uint64_t profileKeyCredentialPresentationLen,
                                                               uint8_t *uuidCiphertextOut,
                                                               uint64_t uuidCiphertextLen);

int32_t FFI_ProfileKeyCredentialRequestContext_checkValidContents(const uint8_t *profileKeyCredentialRequestContext,
                                                                  uint64_t profileKeyCredentialRequestContextLen);

int32_t FFI_ProfileKeyCredentialRequestContext_getRequest(const uint8_t *profileKeyCredentialRequestContext,
                                                          uint64_t profileKeyCredentialRequestContextLen,
                                                          uint8_t *profileKeyCredentialRequestOut,
                                                          uint64_t profileKeyCredentialRequestLen);

int32_t FFI_ProfileKeyCredentialRequest_checkValidContents(const uint8_t *profileKeyCredentialRequest,
                                                           uint64_t profileKeyCredentialRequestLen);

int32_t FFI_ProfileKeyCredentialResponse_checkValidContents(const uint8_t *profileKeyCredentialResponse,
                                                            uint64_t profileKeyCredentialResponseLen);

int32_t FFI_ProfileKeyCredential_checkValidContents(const uint8_t *profileKeyCredential,
                                                    uint64_t profileKeyCredentialLen);

int32_t FFI_ProfileKey_getCommitment(const uint8_t *profileKey,
                                     uint64_t profileKeyLen,
                                     const uint8_t *uuid,
                                     uint64_t uuidLen,
                                     uint8_t *profileKeyCommitmentOut,
                                     uint64_t profileKeyCommitmentLen);

int32_t FFI_ProfileKey_getProfileKeyVersion(const uint8_t *profileKey,
                                            uint64_t profileKeyLen,
                                            const uint8_t *uuid,
                                            uint64_t uuidLen,
                                            uint8_t *profileKeyVersionOut,
                                            uint64_t profileKeyVersionLen);

int32_t FFI_Randomness_checkValidContents(const uint8_t *randomness, uint64_t randomnessLen);

int32_t FFI_ServerPublicParams_checkValidContents(const uint8_t *serverPublicParams,
                                                  uint64_t serverPublicParamsLen);

int32_t FFI_ServerPublicParams_createAuthCredentialPresentationDeterministic(const uint8_t *serverPublicParams,
                                                                             uint64_t serverPublicParamsLen,
                                                                             const uint8_t *randomness,
                                                                             uint64_t randomnessLen,
                                                                             const uint8_t *groupSecretParams,
                                                                             uint64_t groupSecretParamsLen,
                                                                             const uint8_t *authCredential,
                                                                             uint64_t authCredentialLen,
                                                                             uint8_t *authCredentialPresentationOut,
                                                                             uint64_t authCredentialPresentationLen);

int32_t FFI_ServerPublicParams_createProfileKeyCredentialPresentationDeterministic(const uint8_t *serverPublicParams,
                                                                                   uint64_t serverPublicParamsLen,
                                                                                   const uint8_t *randomness,
                                                                                   uint64_t randomnessLen,
                                                                                   const uint8_t *groupSecretParams,
                                                                                   uint64_t groupSecretParamsLen,
                                                                                   const uint8_t *profileKeyCredential,
                                                                                   uint64_t profileKeyCredentialLen,
                                                                                   uint8_t *profileKeyCredentialPresentationOut,
                                                                                   uint64_t profileKeyCredentialPresentationLen);

int32_t FFI_ServerPublicParams_createProfileKeyCredentialRequestContextDeterministic(const uint8_t *serverPublicParams,
                                                                                     uint64_t serverPublicParamsLen,
                                                                                     const uint8_t *randomness,
                                                                                     uint64_t randomnessLen,
                                                                                     const uint8_t *uuid,
                                                                                     uint64_t uuidLen,
                                                                                     const uint8_t *profileKey,
                                                                                     uint64_t profileKeyLen,
                                                                                     uint8_t *profileKeyCredentialRequestContextOut,
                                                                                     uint64_t profileKeyCredentialRequestContextLen);

int32_t FFI_ServerPublicParams_receiveAuthCredential(const uint8_t *serverPublicParams,
                                                     uint64_t serverPublicParamsLen,
                                                     const uint8_t *uuid,
                                                     uint64_t uuidLen,
                                                     uint32_t redemptionTime,
                                                     const uint8_t *authCredentialResponse,
                                                     uint64_t authCredentialResponseLen,
                                                     uint8_t *authCredentialOut,
                                                     uint64_t authCredentialLen);

int32_t FFI_ServerPublicParams_receiveProfileKeyCredential(const uint8_t *serverPublicParams,
                                                           uint64_t serverPublicParamsLen,
                                                           const uint8_t *profileKeyCredentialRequestContext,
                                                           uint64_t profileKeyCredentialRequestContextLen,
                                                           const uint8_t *profileKeyCredentialResponse,
                                                           uint64_t profileKeyCredentialResponseLen,
                                                           uint8_t *profileKeyCredentialOut,
                                                           uint64_t profileKeyCredentialLen);

int32_t FFI_ServerPublicParams_verifySignature(const uint8_t *serverPublicParams,
                                               uint64_t serverPublicParamsLen,
                                               const uint8_t *message,
                                               uint64_t messageLen,
                                               const uint8_t *notarySignature,
                                               uint64_t notarySignatureLen);

int32_t FFI_ServerSecretParams_checkValidContents(const uint8_t *serverSecretParams,
                                                  uint64_t serverSecretParamsLen);

int32_t FFI_ServerSecretParams_generateDeterministic(const uint8_t *randomness,
                                                     uint64_t randomnessLen,
                                                     uint8_t *serverSecretParamsOut,
                                                     uint64_t serverSecretParamsLen);

int32_t FFI_ServerSecretParams_getPublicParams(const uint8_t *serverSecretParams,
                                               uint64_t serverSecretParamsLen,
                                               uint8_t *serverPublicParamsOut,
                                               uint64_t serverPublicParamsLen);

int32_t FFI_ServerSecretParams_issueAuthCredentialDeterministic(const uint8_t *serverSecretParams,
                                                                uint64_t serverSecretParamsLen,
                                                                const uint8_t *randomness,
                                                                uint64_t randomnessLen,
                                                                const uint8_t *uuid,
                                                                uint64_t uuidLen,
                                                                uint32_t redemptionTime,
                                                                uint8_t *authCredentialResponseOut,
                                                                uint64_t authCredentialResponseLen);

int32_t FFI_ServerSecretParams_issueProfileKeyCredentialDeterministic(const uint8_t *serverSecretParams,
                                                                      uint64_t serverSecretParamsLen,
                                                                      const uint8_t *randomness,
                                                                      uint64_t randomnessLen,
                                                                      const uint8_t *profileKeyCredentialRequest,
                                                                      uint64_t profileKeyCredentialRequestLen,
                                                                      const uint8_t *uuid,
                                                                      uint64_t uuidLen,
                                                                      const uint8_t *profileKeyCommitment,
                                                                      uint64_t profileKeyCommitmentLen,
                                                                      uint8_t *profileKeyCredentialResponseOut,
                                                                      uint64_t profileKeyCredentialResponseLen);

int32_t FFI_ServerSecretParams_signDeterministic(const uint8_t *serverSecretParams,
                                                 uint64_t serverSecretParamsLen,
                                                 const uint8_t *randomness,
                                                 uint64_t randomnessLen,
                                                 const uint8_t *message,
                                                 uint64_t messageLen,
                                                 uint8_t *notarySignatureOut,
                                                 uint64_t notarySignatureLen);

int32_t FFI_ServerSecretParams_verifyAuthCredentialPresentation(const uint8_t *serverSecretParams,
                                                                uint64_t serverSecretParamsLen,
                                                                const uint8_t *groupPublicParams,
                                                                uint64_t groupPublicParamsLen,
                                                                const uint8_t *authCredentialPresentation,
                                                                uint64_t authCredentialPresentationLen);

int32_t FFI_ServerSecretParams_verifyProfileKeyCredentialPresentation(const uint8_t *serverSecretParams,
                                                                      uint64_t serverSecretParamsLen,
                                                                      const uint8_t *groupPublicParams,
                                                                      uint64_t groupPublicParamsLen,
                                                                      const uint8_t *profileKeyCredentialPresentation,
                                                                      uint64_t profileKeyCredentialPresentationLen);

int32_t FFI_UuidCiphertext_checkValidContents(const uint8_t *uuidCiphertext,
                                              uint64_t uuidCiphertextLen);

int32_t FFI_Uuid_checkValidContents(const uint8_t *uuid, uint64_t uuidLen);
