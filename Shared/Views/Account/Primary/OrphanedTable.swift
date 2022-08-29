//
//  OrphanedTable.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import Tabler
import AllocData

import FlowAllocLow
import FlowBase
import FlowAllocHigh
import FlowUI

struct OrphanedTable: View {
    @Binding var document: AllocatDocument
    
    var account: MAccount
    
    var body: some View {
        TablerStack(.init(rowSpacing: flowRowSpacing),
                    header: header,
                    row: row,
                    rowBackground: rowBackground,
                    results: assetKeys)
            .sideways(minWidth: 800, showIndicators: true)
    }
    
    private let gridItems: [GridItem] = [
        GridItem(.flexible(minimum: 200), spacing: columnSpacing),
        GridItem(.flexible(minimum: 200), spacing: columnSpacing),
    ]
    
    private func header(ctx: Binding<TablerContext<AssetKey>>) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: flowColumnSpacing) {
            Text("Asset Class")
                .modifier(HeaderCell())
            Text("Orphaned Amount")
                .modifier(HeaderCell())
        }
    }
    
    private func row(_ assetKey: AssetKey) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: flowColumnSpacing) {
            VStack {
                Text(getAssetClassTitle(assetKey))
                    .fontWeight(.bold)
                if isGroupRelatedHoldings {
                    ForEach(getRelations(assetKey), id: \.self) { childAssetKey in
                        Text(getAssetClassTitle(childAssetKey))
                            .italic()
                    }
                }
            }
            .mpadding()
            CurrencyLabel(value: getOrphanedAmount(assetKey), ifZero: "")
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
        ax.topRankedHoldingAssetKeysMap[targetAssetKey, default: []]
    }
    
    private var accountKey: AccountKey {
        account.primaryKey
    }
    
    // assetKeys, sorted by asset titles
    private var assetKeys: [AssetKey] {
        let assetMap = ax.assetMap
        guard let assetAmountMap = ax.fixedOrphanedMap[accountKey] else { return [] }
        return assetAmountMap.keys.compactMap { assetMap[$0] }.sorted().map(\.primaryKey)
    }
    
    private func getOrphanedAmount(_ assetKey: AssetKey) -> Double {
        ax.fixedOrphanedMap[accountKey]?[assetKey] ?? 0
    }
    
    private func getAssetClassTitle(_ assetKey: AssetKey) -> String {
        ax.assetMap[assetKey]?.title ?? ""
    }
    
    private func rowBackground(assetKey: AssetKey) -> some View {
        document.getBackgroundFill(assetKey)
    }
    
    private func colorPair(_ assetKey: AssetKey) -> (Color, Color) {
        let colorCode = document.context.colorCodeMap[assetKey] ?? 0
        return getColor(colorCode)
    }
}
