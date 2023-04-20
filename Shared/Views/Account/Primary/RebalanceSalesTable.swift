//
//  RebalanceSalesTable.swift
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

struct RebalanceSalesTable: View {
    @Binding var document: AllocatDocument

    var account: MAccount
    var salesMap: SaleMap

    private let gridItems: [GridItem] = [
        GridItem(.flexible(minimum: 200.0), spacing: columnSpacing),
        GridItem(.flexible(minimum: 100.0), spacing: columnSpacing),
        GridItem(.flexible(minimum: 100.0), spacing: columnSpacing),
        GridItem(.flexible(minimum: 100.0), spacing: columnSpacing),
        GridItem(.flexible(minimum: 100.0), spacing: columnSpacing),
        GridItem(.flexible(minimum: 200.0), spacing: columnSpacing),
        GridItem(.flexible(minimum: 100.0), spacing: columnSpacing),
        GridItem(.flexible(minimum: 100.0), spacing: columnSpacing),
    ]

    var body: some View {
        TablerStack(.init(rowSpacing: flowRowSpacing),
                    header: header,
                    row: row,
                    rowBackground: rowBackground,
                    results: sales)
            .sideways(minWidth: 1400, showIndicators: true)
    }

    private func header(ctx _: Binding<TablerContext<Sale>>) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: flowColumnSpacing) {
            Text("Asset Class")
                .modifier(HeaderCell())
            Text("Net Rebalance")
                .modifier(HeaderCell())
            Text("Sale Proceeds")
                .modifier(HeaderCell())
            Text("Net Gain (loss)")
                .modifier(HeaderCell())
            Text("Absolute Gains")
                .modifier(HeaderCell())
            Text("Liquidations")
                .modifier(HeaderCell())
            Text("Wash Sale")
                .modifier(HeaderCell())
            Text("Recent Purchases")
                .modifier(HeaderCell())
        }
    }

    private func row(_ sale: Sale) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: flowColumnSpacing) {
            Text(getAssetClassTitle(sale.assetKey))
                .mpadding()
            VStack {
                if let amount = netRebalanceMap[sale.assetKey] {
                    CurrencyLabel(value: amount)
                }
            }
            .mpadding()
            CurrencyLabel(value: sale.proceeds)
                .mpadding()
            CurrencyLabel(value: sale.netGainLoss)
                .mpadding()
            CurrencyLabel(value: sale.absoluteGains)
                .mpadding()
            VStack {
                ForEach(sale.liquidateHoldings, id: \.self) { lh in
                    LiquidateLabel(document: $document, liquidateHolding: lh)
                }
            }
            .mpadding()
            CurrencyLabel(value: getSaleWashAmount(sale), ifZero: "")
                .mpadding()
            VStack {
                ForEach(document.getRecentPurchases(sale.assetKey), id: \.self) { purchase in
                    Text(purchase)
                }
            }
            .mpadding()
        }
        .foregroundColor(colorPair(sale.assetKey).0)
    }

    // MARK: - Helpers

    private var ax: HighContext {
        document.context
    }

    private func getSaleWashAmount(_ sale: Sale) -> Double {
        sale.getWashAmount(recentPurchasesMap: ax.recentPurchasesMap,
                           securityMap: ax.securityMap,
                           trackerSecuritiesMap: ax.trackerSecuritiesMap)
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

    private var netRebalanceMap: RebalanceMap {
        ax.isReduceRebalance ? applyReducerMap(baseRebalanceMap, reducerMap, preserveZero: false) : baseRebalanceMap
    }

    // NOTE: the base rebalance map should have the full list of assetKeys prior to the rebalance
    private var sales: [Sale] {
        let assetKeys = netRebalanceMap.map(\.key).sorted()
        return assetKeys.compactMap { salesMap[$0] }
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

    private func rowBackground(sale: Sale) -> some View {
        document.getBackgroundFill(sale.assetKey)
    }

    private func colorPair(_ assetKey: AssetKey) -> (Color, Color) {
        let colorCode = document.context.colorCodeMap[assetKey] ?? 0
        return getColor(colorCode)
    }
}
