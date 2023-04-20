//
//  Packaging-Rebalance.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

import ZIPFoundation

import AllocData
import FINporter

import FlowAllocHigh
import FlowAllocLow
import FlowBase

private let rebalancePackageFormat: AllocFormat = .CSV

public func packageRebalance(params: BaseParams,
                             tradingAllocations: [MRebalanceAllocation],
                             nonTradingAllocations: [MRebalanceAllocation],
                             mpurchases: [MRebalancePurchase],
                             msales: [MRebalanceSale]) throws -> Data
{
    guard let archive = Archive(accessMode: .create)
    else { throw FlowBaseError.archiveCreateFailure }

    let fileExt = rebalancePackageFormat.defaultFileExtension!

    let trading = try exportData(tradingAllocations, format: rebalancePackageFormat)
    try archive.addEntry(with: "trading-allocations.\(fileExt)",
                         type: .file,
                         uncompressedSize: Int64(trading.count),
                         provider: { position, size -> Data in
                             let range = Int(position) ..< Int(position) + size
                             return trading.subdata(in: range)
                         })

    let nonTrading = try exportData(nonTradingAllocations, format: rebalancePackageFormat)
    try archive.addEntry(with: "non-trading-allocations.\(fileExt)",
                         type: .file,
                         uncompressedSize: Int64(nonTrading.count),
                         provider: { position, size -> Data in
                             let range = Int(position) ..< Int(position) + size
                             return nonTrading.subdata(in: range)
                         })

    let exportedPurchases = try exportData(mpurchases, format: rebalancePackageFormat)
    try archive.addEntry(with: "purchases.\(fileExt)",
                         type: .file,
                         uncompressedSize: Int64(exportedPurchases.count),
                         provider: { position, size -> Data in
                             let range = Int(position) ..< Int(position) + size
                             return exportedPurchases.subdata(in: range)
                         })

    let exportedSales = try exportData(msales, format: rebalancePackageFormat)
    try archive.addEntry(with: "sales.\(fileExt)",
                         type: .file,
                         uncompressedSize: Int64(exportedSales.count),
                         provider: { position, size -> Data in
                             let range = Int(position) ..< Int(position) + size
                             return exportedSales.subdata(in: range)
                         })

    let paramsData: Data = try StorageManager.encodeToJSON(params)
    try archive.addEntry(with: "params.json",
                         type: .file,
                         uncompressedSize: Int64(paramsData.count),
                         provider: { position, size -> Data in
                             let range = Int(position) ..< Int(position) + size
                             return paramsData.subdata(in: range)
                         })

    return archive.data!
}
