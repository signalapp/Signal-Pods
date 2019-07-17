//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation
import SignalMetadataKit

public class MockAccountIdFinder: SMKAccountIdFinder {
    typealias AccountId = String

    private var uuidToIdMap: [UUID: AccountId] = [:]
    private var phoneNumberToIdMap: [String: AccountId] = [:]

    public func accountId(forUuid uuid: UUID?, phoneNumber: String?, protocolContext: SPKProtocolWriteContext?) -> String? {
        assert(uuid != nil || phoneNumber != nil)

        if let uuid = uuid {
            if let existingIdFromUuid = uuidToIdMap[uuid] {
                if let phoneNumber = phoneNumber {
                    assert(phoneNumberToIdMap[phoneNumber] == existingIdFromUuid, "mock finder maps must be kept in sync")
                }
                return existingIdFromUuid
            }
        }

        if let phoneNumber = phoneNumber {
            if let existingIdFromPhoneNumber = phoneNumberToIdMap[phoneNumber] {
                if let uuid = uuid {
                    assert(uuidToIdMap[uuid] == existingIdFromPhoneNumber, "mock finder maps must be kept in sync")
                }
                return existingIdFromPhoneNumber
            }
        }

        let newAccountId = UUID().uuidString
        if let uuid = uuid {
            uuidToIdMap[uuid] = newAccountId
        }

        if let phoneNumber = phoneNumber {
            phoneNumberToIdMap[phoneNumber] = newAccountId
        }

        return newAccountId
    }
}
