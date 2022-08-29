//
//  AllocatDocument+Helpers.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

import AllocData

import FlowAllocLow
import FlowBase
import FlowAllocHigh

extension AllocatDocument {
    
    // MARK: - Active Strategy/Accounts Helpers
    
    var activeStrategyKey: StrategyKey {
        modelSettings.activeStrategyKey
    }
    
    /// returns nil if no active strategy
    var activeStrategy: MStrategy? {
        guard activeStrategyKey.isValid
        else { return nil }
        return context.strategyMap[activeStrategyKey]
    }
    
    /// returns [] if no active strategy or no accounts assigned to strategy
    var activeAccounts: [MAccount] {
        model.getActiveAccounts(strategyKey: activeStrategyKey)
    }

    /// returns [] if no active strategy or no accounts assigned to strategy
    var activeAccountKeys: [AccountKey] {
        activeAccounts.map(\.primaryKey)
    }
    
    // MARK: - helpers for formatted results

    // Recent sales in this asset class that realized a loss in a taxable account.
    // Purchasing similar securities will forego your tax deduction on the loss.
    // NOTE: does not include any realized losses in current rebalance!
    func getRecentRealizedLosses(_ assetKey: AssetKey) -> [String] {
        guard let map = context.assetRecentNetGainsMap[assetKey]
        else { return [] }
        let tuples = map.filter { $0.value < 0 }.sorted(by: { $0.value < $1.value })
        return tuples.map { "\(getTicker($0.key) ?? "") \($0.value.toCurrency(style: .compact))" }
    }

    func getRecentPurchases(_ assetKey: AssetKey) -> [String] {
        guard let map = context.assetRecentPurchaseMap[assetKey]
        else { return [] }
        let tuples = map.filter { $0.value > 0 }.sorted(by: { $0.value < $1.value })
        return tuples.map { "\(getTicker($0.key) ?? "") \($0.value.toCurrency(style: .compact))" }
    }

    private func getTicker(_ securityKey: SecurityKey) -> SecurityID? {
        context.securityMap[securityKey]?.securityID
    }

    mutating func shuffleAction() {
        displaySettings.params.accountKeys.shuffle()
        displaySettings.params.fixedAccountKeys.shuffle()
        displaySettings.params.assetKeys.shuffle()
        displaySettings.params.flowMode = Double.random(in: 0 ... 1)
        refreshHighResult()
    }
}

extension AllocatDocument {
    func optimizeAbort() {
        optimize.cancelOperationsAction()
        optimize.clearAction()
    }
}
