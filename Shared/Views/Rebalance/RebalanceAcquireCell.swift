//
//  RebalanceAcquireCell.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//


import SwiftUI

import AllocData

import FlowAllocLow
import FlowBase
import FlowAllocHigh

struct RebalanceAcquireCell: View {
    @Binding var document: AllocatDocument

    var account: MAccount
    var purchase: Purchase
    var losingTaxableSales: [String]
    var netPurchaseAmount: Double // 'Reduce Rebalance' feature affects this

    var body: some View {
        BaseRebalanceCell(document: $document,
                          title: "Buy",
                          amount: netPurchaseAmount,
                          assetKey: purchase.assetKey,
                          rowContent: rowContent)
    }

    @ViewBuilder
    private func rowContent() -> some View {
        
        let losses: [String] = recentRealizedLosses
        if losses.count > 0 {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "w.square.fill")
                Text("Realized: \(losses.joined(separator: ", "))")
            }
        }

        let losingSales: [String] = losingTaxableSales
        if losingSales.count > 0 {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "w.square")
                Text("Losing Sales: \(losingSales.joined(separator: "; "))")
            }
        }

        let holdings = currentlyHolding
        if holdings.count > 0 {
            HStack(alignment: .firstTextBaseline) {
                // WashIndicator(hasConflict: false)
                Image(systemName: "shippingbox.fill")
                Text("Holding: \(holdings.joined(separator: ", "))")
            }
        }

        HStack(alignment: .firstTextBaseline) {
            Image(systemName: "cart.fill")
            Text(netPurchaseAmount.toCurrency(style: .compact, leadingPlus: true))
        }
    }
    
    // MARK: - Properties

    private var ax: HighContext {
        document.context
    }

    private var asset: MAsset? {
        ax.assetMap[purchase.assetKey]
    }

    // recent sales in this asset class that realized a loss in a taxable account
    // purchasing similar securities will forego your tax deduction on the loss
    private var recentRealizedLosses: [String] {
        document.getRecentRealizedLosses(purchase.assetKey)
    }

    private var currentlyHolding: [String] {
        let tickerSummaries: TickerHoldingsSummaryMap = HoldingsSummary.getCurrentlyHolding(ax, accountKey: account.primaryKey, assetKey: purchase.assetKey)
        let sorted = tickerSummaries.sorted(by: { $0.value.presentValue > $1.value.presentValue })
        return sorted.map { "\(getTicker($0.key) ?? "") \($0.value.presentValue.toCurrency(style: .compact))" }
    }

    private func getTicker(_ securityKey: SecurityKey) -> SecurityID? {
        ax.securityMap[securityKey]?.securityID
    }

    // MARK: - Helpers

    // display list of securities that we're selling at a loss, if anny  ####
    private var saleWashesToAvoid: TickerAmountMap {
        guard let map = ax.assetRecentNetGainsMap[purchase.assetKey]
        else { return [:] }
        return map.filter { $0.value < 0 }
    }
}
