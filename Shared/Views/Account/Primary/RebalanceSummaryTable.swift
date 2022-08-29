//
//  RebalanceSummaryTable.swift
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

struct RebalanceSummaryTable: View {
    @Binding var document: AllocatDocument
    
    var account: MAccount
    
    private var gridItems: [GridItem] {
        var buffer = [GridItem]()
        
        buffer.append( GridItem(.flexible(minimum: 200)))
        buffer.append( GridItem(.flexible(minimum: 100)))
        
        if isReduceRebalance {
            buffer.append( GridItem(.flexible(minimum: 100)))
            buffer.append( GridItem(.flexible(minimum: 100)))
            buffer.append( GridItem(.flexible(minimum: 100)))
        }
        
        return buffer
    }
    
    var body: some View {
        TablerStack(.init(rowSpacing: flowRowSpacing),
                    header: header,
                    row: row,
                    rowBackground: rowBackground,
                    results: assetKeys)
            .sideways(minWidth: 600, showIndicators: true)
    }
    
    private func header(ctx: Binding<TablerContext<AssetKey>>) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: flowColumnSpacing) {
            if isReduceRebalance {
                Text("Rebalance Reduction Group")
                    .modifier(HeaderCell())
            } else {
                Text("Target Asset Class")
                    .modifier(HeaderCell())
            }
            Text("Base Rebalance")
                .modifier(HeaderCell())
            if isReduceRebalance {
                Text("Offsetting Asset(s)")
                    .modifier(HeaderCell())
                Text("Offset Amount(s)")
                    .modifier(HeaderCell())
                Text("Net Rebalance")
                    .modifier(HeaderCell())
            }
        }
    }
    
    private func row(_ assetKey: AssetKey) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: flowColumnSpacing) {
            VStack {
                Text(getAssetClassTitle(assetKey))
                    .fontWeight(.bold)
                if isReduceRebalance {
                    ForEach(getRelations(assetKey), id: \.self) { relatedAssetKey in
                        if relatedAssetKey != assetKey {
                            Text(getAssetClassTitle(relatedAssetKey))
                                .italic()
                        }
                    }
                }
            }
            .mpadding()
            VStack {
                if let amount = rebalanceMap[assetKey] {
                    CurrencyLabel(value: amount)
                }
            }
            .mpadding()
            if isReduceRebalance {
                let allocs = getReductions(assetKey)
                VStack {
                    ForEach(allocs, id: \.self) { alloc in
                        Text(getAssetClassTitle(alloc.assetKey))
                    }
                }
                .mpadding()
                VStack {
                    ForEach(allocs, id: \.self) { alloc in
                        CurrencyLabel(value: alloc.value)
                    }
                }
                .mpadding()
                VStack {
                    if let amount = netRebalanceMap[assetKey] {
                        CurrencyLabel(value: amount)
                    }
                }
                .mpadding()
            }
        }
        .foregroundColor(colorPair(assetKey).0)
    }
    
    // MARK: - Helpers
    
    private var ax: HighContext {
        document.context
    }
    
    private var assetKeys: [AssetKey] {
        let assetMap = ax.assetMap
        let map = isReduceRebalance ? netRebalanceMap : rebalanceMap
        return map.map(\.key).compactMap { assetMap[$0] }.sorted().map(\.primaryKey)
    }
    
    private var accountKey: AccountKey {
        account.primaryKey
    }
    
    private var isReduceRebalance: Bool {
        ax.isReduceRebalance
    }
    
    private var rebalanceMap: RebalanceMap {
        document.allocationResult.accountRebalanceMap[accountKey] ?? [:]
    }
    
    private var reducerMap: ReducerMap {
        document.allocationResult.accountReducerMap[accountKey] ?? [:]
    }
    
    private func getReductions(_ assetKey: AssetKey) -> [AssetValue] {
        reducerMap.compactMap { pair, amount in
            if assetKey == pair.left {
                return AssetValue(pair.right, amount)
            } else if assetKey == pair.right {
                return AssetValue(pair.left, -1 * amount)
            }
            return nil
        }
    }
    
    // get the asset keys related to the target
    private func getRelations(_ targetAssetKey: AssetKey) -> [AssetKey] {
        ax.topRankedHoldingAssetKeysMap[targetAssetKey] ?? []
    }
    
    private var netRebalanceMap: RebalanceMap {
        applyReducerMap(rebalanceMap, reducerMap, preserveZero: true)
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
    
    private func rowBackground(assetKey: AssetKey) -> some View {
        document.getBackgroundFill(assetKey)
    }
    
    private func colorPair(_ assetKey: AssetKey) -> (Color, Color) {
        let colorCode = document.context.colorCodeMap[assetKey] ?? 0
        return getColor(colorCode)
    }
}
