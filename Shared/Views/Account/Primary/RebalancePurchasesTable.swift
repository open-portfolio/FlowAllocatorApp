//
//  RebalancePurchasesTable.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import AllocData
import Tabler

import FlowAllocHigh
import FlowAllocLow
import FlowBase
import FlowUI

struct RebalancePurchasesTable: View {
    @Binding var document: AllocatDocument

    var account: MAccount
    var purchasesMap: PurchaseMap
    var losingSalesMap: AssetSalesMap

    private let gridItems: [GridItem] = [
        GridItem(.flexible(minimum: 200.0), spacing: columnSpacing),
        GridItem(.flexible(minimum: 100.0), spacing: columnSpacing),
        GridItem(.flexible(minimum: 100.0), spacing: columnSpacing),
        GridItem(.flexible(minimum: 100.0), spacing: columnSpacing),
        GridItem(.flexible(minimum: 100.0), spacing: columnSpacing),
        GridItem(.flexible(minimum: 100.0), spacing: columnSpacing),
        GridItem(.flexible(minimum: 100.0), spacing: columnSpacing),
    ]

    var body: some View {
        TablerStack(.init(rowSpacing: flowRowSpacing),
                    header: header,
                    row: row,
                    rowBackground: rowBackground,
                    results: purchases)
            .sideways(minWidth: 1200, showIndicators: true)
    }

    private func header(ctx _: Binding<TablerContext<Purchase>>) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: flowColumnSpacing) {
            Text("Asset Class")
                .modifier(HeaderCell())
            Text("Net Rebalance")
                .modifier(HeaderCell())
            Text("Purchase Amount")
                .modifier(HeaderCell())
            Text("Currently Holding")
                .modifier(HeaderCell())
            Text("Wash Sale")
                .modifier(HeaderCell())
            Text("Realized Losses")
                .modifier(HeaderCell())
            Text("Losing Sales")
                .modifier(HeaderCell())
        }
    }

    private func row(_ purchase: Purchase) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: flowColumnSpacing) {
            Text(getAssetClassTitle(purchase.assetKey))
                .mpadding()

            VStack {
                if let amount = netRebalanceMap[purchase.assetKey] {
                    CurrencyLabel(value: amount)
                }
            }
            .mpadding()

            CurrencyLabel(value: purchase.amount)
                .mpadding()
            VStack {
                ForEach(getCurrentlyHolding(assetKey: purchase.assetKey), id: \.self) { holding in
                    Text(holding)
                }
            }
            .mpadding()

            CurrencyLabel(value: getWashAmount(purchase), ifZero: "")
                .mpadding()

            VStack {
                ForEach(document.getRecentRealizedLosses(purchase.assetKey), id: \.self) { loss in
                    Text(loss)
                }
            }
            .mpadding()

            VStack {
                ForEach(losingTaxableSales(assetKey: purchase.assetKey), id: \.self) { loss in
                    Text(loss)
                }
            }
            .mpadding()
        }
        .foregroundColor(colorPair(purchase.assetKey).0)
    }

    // MARK: - Helpers

    private var ax: HighContext {
        document.context
    }

    private func getWashAmount(_ purchase: Purchase) -> Double {
        let sellMap = document.context.assetSellTxnsMap
        return purchase.getWashAmount(assetSellTxnsMap: sellMap)
    }

    private func getCurrentlyHolding(assetKey: AssetKey) -> [String] {
        let tickerSummaries = HoldingsSummary.getCurrentlyHolding(ax, accountKey: account.primaryKey, assetKey: assetKey)
        let sorted = tickerSummaries.sorted(by: { $0.value.presentValue > $1.value.presentValue })
        return sorted.map { "\(getTicker($0.key) ?? "") \($0.value.presentValue.toCurrency(style: .compact))" }
    }

    private func getTicker(_ securityKey: SecurityKey) -> SecurityID? {
        ax.securityMap[securityKey]?.securityID
    }

    private var accountKey: AccountKey {
        account.primaryKey
    }

    private var baseRebalanceMap: RebalanceMap {
        document.allocationResult.accountRebalanceMap[accountKey] ?? [:]
    }

    private var reducerMap: ReducerMap {
        document.allocationResult.accountReducerMap[accountKey] ?? [:]
    }

    // selectively display the reduced rebalance, so user can toggle command-D
    private var netRebalanceMap: RebalanceMap {
        ax.isReduceRebalance ? applyReducerMap(baseRebalanceMap, reducerMap, preserveZero: false) : baseRebalanceMap
    }

    // NOTE: the base rebalance map should have the full list of assetKeys prior to the rebalance
    private var purchases: [Purchase] {
        let assetKeys = netRebalanceMap.map(\.key).sorted()
        return assetKeys.compactMap { purchasesMap[$0] }
    }

    private var assetMap: AssetMap {
        if ax.assetMap.count > 0 {
            return ax.assetMap
        }
        return document.model.makeAssetMap()
    }

    private func getAssetClassTitle(_ assetKey: AssetKey) -> String {
        assetMap[assetKey]?.titleID ?? ""
    }

    // TODO: summarize by loss on each securityID (using liquidateHoldings)
    private func losingTaxableSales(assetKey: AssetKey) -> [String] {
        guard let losingSales = losingSalesMap[assetKey] else { return [] }
        return losingSales.reduce(into: []) {
            let tickers = $1.tickerKeys.map(\.securityNormID)
            let str = "\(tickers.map(\.localizedUppercase).joined(separator: "/")) \($1.netGainLoss.toCurrency(style: .compact))"
            $0.append(str)
        }
    }

    private func rowBackground(purchase: Purchase) -> some View {
        document.getBackgroundFill(purchase.assetKey)
        // colorPair(purchase.assetKey).1
    }

    private func colorPair(_ assetKey: AssetKey) -> (Color, Color) {
        let colorCode = document.context.colorCodeMap[assetKey] ?? 0
        return getColor(colorCode)
    }
}

//    private func getRecentRealized(_ assetKey: AssetKey) -> [String] {
//        guard let ax = document.surgeContext,
//              let recentTxns = ax.assetTxnsMap[assetKey]
//        else { return [] }
//        let map = MTransaction.getNetRealizedGainMap(recentTxns: recentTxns)
//        return map.sorted(by: { $0.key < $1.key }).map { "\($0.key.uppercased()): \($0.value.toCurrency(style: .compact))" }
//    }

// recent sales in this asset class that realized a loss in a taxable account
// purchasing similar securities will forego your tax deduction on the loss
//    private func getRecentRealizedLosses(assetKey: AssetKey) -> [String] {
//        document.getRecentRealizedLosses(assetKey)
//    }
