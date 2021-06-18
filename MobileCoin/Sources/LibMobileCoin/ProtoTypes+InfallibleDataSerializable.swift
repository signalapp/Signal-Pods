// swiftlint:disable:this file_name

//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

// MARK: - External

extension External_AccountKey: InfallibleDataSerializable {}

extension External_PublicAddress: InfallibleDataSerializable {}

extension External_TxOutMembershipProof: InfallibleDataSerializable {}

extension External_TxOut: InfallibleDataSerializable {}

extension External_Tx: InfallibleDataSerializable {}

extension External_Receipt: InfallibleDataSerializable {}

// MARK: - Printable

extension Printable_PrintableWrapper: InfallibleDataSerializable {}

// MARK: - Attest

extension Attest_Message: InfallibleDataSerializable {}

// MARK: - Fog Report

extension Report_ReportResponse: InfallibleDataSerializable {}

// MARK: - Fog View

extension FogView_QueryRequestAAD: InfallibleDataSerializable {}
extension FogView_QueryRequest: InfallibleDataSerializable {}
extension FogView_QueryResponse: InfallibleDataSerializable {}

extension FogView_TxOutRecord: InfallibleDataSerializable {}

// MARK: - Fog Ledger

extension FogLedger_GetOutputsRequest: InfallibleDataSerializable {}
extension FogLedger_GetOutputsResponse: InfallibleDataSerializable {}

extension FogLedger_CheckKeyImagesRequest: InfallibleDataSerializable {}
extension FogLedger_CheckKeyImagesResponse: InfallibleDataSerializable {}
