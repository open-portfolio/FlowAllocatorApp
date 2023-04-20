//
//  AccountAllocTable.swift
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

struct ParticipatingHoldingsTable: View {
    @Binding var document: AllocatDocument
    var account: MAccount

    private let gridItems: [GridItem] = [
        GridItem(.flexible(minimum: 150, maximum: 250), spacing: columnSpacing),
        GridItem(.flexible(minimum: 80, maximum: 250), spacing: columnSpacing),
        GridItem(.flexible(minimum: 100, maximum: 250), spacing: columnSpacing),
        GridItem(.flexible(minimum: 100, maximum: 250), spacing: columnSpacing),
    ]

    var body: some View {
        TablerStack(.init(rowSpacing: flowRowSpacing),
                    header: header,
                    row: row,
                    rowBackground: rowBackground,
                    results: assetKeys)
            .sideways(minWidth: 800, showIndicators: true)
    }

    private func header(ctx _: Binding<TablerContext<AssetKey>>) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: flowColumnSpacing) {
            if isGroupRelatedHoldings {
                Text("Asset Class Group")
                    .modifier(HeaderCell())
            } else {
                Text("Target Asset Class")
                    .modifier(HeaderCell())
            }
            Text("Holding(s)")
                .modifier(HeaderCell())
            Text("Amount(s) Held")
                .modifier(HeaderCell())
            Text("Asset Target Amount")
                .modifier(HeaderCell())
        }
    }

    private func row(assetKey: AssetKey) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: flowColumnSpacing) {
            VStack {
                Text(getAssetClassTitle(assetKey))
                    .fontWeight(.bold)
                if isGroupRelatedHoldings {
                    ForEach(getRelations(assetKey), id: \.self) { relatedAssetKey in
                        if relatedAssetKey != assetKey {
                            Text(getAssetClassTitle(relatedAssetKey))
                                .italic()
                        }
                    }
                }
            }
            .mpadding()
            HoldingsCell(ax: document.context,
                         tickerSummaryMap: getTickerSummaryMap(for: assetKey),
                         field: .ticker)
                .mpadding()
            HoldingsCell(ax: document.context,
                         tickerSummaryMap: getTickerSummaryMap(for: assetKey),
                         field: .presentValue)
                .mpadding()
            CurrencyLabel(value: getAllocAmount(assetKey), ifZero: "", style: .whole)
                .mpadding()
        }
        .foregroundColor(colorPair(assetKey).0)
    }

    // MARK: - Helpers

    private var ax: HighContext {
        document.context
    }

    private var isGroupRelatedHoldings: Bool {
        ax.isGroupRelatedHoldings
    }

    private func getRelations(_ targetAssetKey: AssetKey) -> [AssetKey] {
        ax.topRankedHoldingAssetKeysMap[targetAssetKey] ?? []
    }

    private var accountKey: AccountKey {
        account.primaryKey
    }

    private func getAllocAmount(_ assetKey: AssetKey) -> Double {
        guard let map = account.canTrade ? document.allocationResult.accountAllocMap[accountKey] : ax.fixedAccountAllocationMap[accountKey],
              let targetPct = map[assetKey],
              let accountPV = ax.baseAccountPresentValueMap[accountKey]
        else { return 0 }
        return accountPV * targetPct
    }

    private func getHoldings(for assetKey: AssetKey) -> [MHolding] {
        assetHoldingsMap[assetKey] ?? []
    }

    private func getTickerSummaryMap(for assetKey: AssetKey) -> TickerHoldingsSummaryMap {
        let holdings = getHoldings(for: assetKey)
        return HoldingsSummary.getTickerSummaryMap(holdings, ax.securityMap)
    }

    private var assetHoldingsMap: AssetHoldingsMap {
        // NOTE we're not using 'merged' here because we're intentionally excluding the orphans
        guard let map = ax.acceptedAccountAssetHoldingsMap[accountKey]
        else { return [:] }
        return map
    }

    private var assetKeys: [AssetKey] {
        let assetMap = ax.assetMap
        return document.displaySettings.params.assetKeys.compactMap { assetMap[$0] }.sorted().map(\.primaryKey)
    }

    private func getAssetClassTitle(_ assetKey: AssetKey) -> String {
        ax.assetMap[assetKey]?.titleID ?? ""
    }

    private func rowBackground(assetKey: AssetKey) -> some View {
        document.getBackgroundFill(assetKey)
    }

    private func colorPair(_ assetKey: AssetKey) -> (Color, Color) {
        let colorCode = document.context.colorCodeMap[assetKey] ?? 0
        return getColor(colorCode)
    }
}
