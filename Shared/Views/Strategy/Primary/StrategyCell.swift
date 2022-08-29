//
//  StrategyCell.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//


import SwiftUI
import UniformTypeIdentifiers

import FlowAllocLow
import FlowBase
import FlowAllocHigh
import FlowUI
import AllocData

extension Text {
    func platformFont() -> Text {
        #if canImport(AppKit) || targetEnvironment(macCatalyst)
            return font(.title)
        #elseif canImport(UIKit)
            return font(.headline)
        #else
            return self
        #endif
    }
}

struct StrategyCell: View {
    @Binding var document: AllocatDocument

    let epsilon = 0.0001

    enum CellType: Int {
        case rowTotal
        case variableHeader
        case variable
        case fixedHeader
        case fixed
        
        var description: String {
            switch self {
            case .rowTotal:
                return "rowTotal"
            case .variableHeader:
                return "variableHeader"
            case .variable:
                return "variable"
            case .fixedHeader:
                return "fixedHeader"
            case .fixed:
                return "fixed"
            }
        }
    }

    let cellType: CellType
    let assetKey: AssetKey // base (may produce multiple allocs for rollup)
    let accountKey: AccountKey? // nil if net, rollup, or header type
    let colorCode: Int
    let moneySelection: MoneySelection
    let assetClassPrefix: Bool
    let categoryColumnWidth: CGFloat

    var body: some View {
        VStack {
            ForEach(allocs, id: \.self) { alloc in
                let invert = shouldInvertColor(alloc)
                HStack {
                    if assetClassPrefix {
                        assetClassLabel(alloc)
                        Spacer()
                    }

                    formattedValue(alloc)
                }
                .padding(.horizontal, 3)
                .padding(.vertical, 5)
                .foregroundColor(invert ? colorPair.1 : colorPair.0)
                .background(invert ? colorPair.0 : colorPair.1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundColor(colorPair.0)
        .background(colorPair.1)
    }

    @ViewBuilder
    private func formattedValue(_ alloc: AssetValue) -> some View {
        
        switch moneySelection {
        case .percentOfAccount:
            PercentLabel(value: alloc.value, ifZero: "")
        case .percentOfStrategy:
            PercentLabel(value: targetValue(alloc) / totalValue, ifZero: "")
        case .amountOfStrategy:
            currencyLabel(value: targetValue(alloc), ifZero: "")
        case .presentValue:
            currencyLabel(value: getHoldingsSummary(alloc.assetKey).presentValue, ifZero: ifZeroX)
        case .gainLossAmount:
            if isCash(alloc.assetKey) {
                Text("")
            } else {
                currencyLabel(value: getHoldingsSummary(alloc.assetKey).gainLoss, ifZero: ifZeroX)
            }
        case .gainLossPercent:
            if isCash(alloc.assetKey) {
                Text("")
            } else {
                PercentLabel(value: getHoldingsSummary(alloc.assetKey).gainLossPercent ?? 0, ifZero: ifZeroX)
            }
        case .orphaned:
            if cellType == .fixedHeader || cellType == .fixed || cellType == .rowTotal {
                currencyLabel(value: getOrphanedAmount(alloc.assetKey), ifZero: "")
            } else {
                Text("")
            }
        }
    }

    private func assetClassLabel(_ alloc: AssetValue) -> some View {
        Text(getAssetClassTitle(alloc.assetKey))
    }

    private func currencyLabel(value: Double, ifZero: String? = nil) -> some View {
        CurrencyLabel(value: value, ifZero: ifZero, style: .whole)
            .frame(maxWidth: cellType == .rowTotal ? categoryColumnWidth : .infinity)
    }

    // MARK: - Helpers

    private var ifZeroX: String? {
        cellType != .rowTotal ? "" : nil
    }
    
    private var ax: HighContext {
        document.context
    }

    private func shouldInvertColor(_ alloc: AssetValue) -> Bool {
        limitPctExceeded(alloc) && moneySelection.isTargetValue
    }

    private func isCash(_ assetKey: AssetKey) -> Bool {
        assetKey == MAsset.cashAssetKey
    }

    private var totalValue: Double {
        ax.netCombinedTotal
    }

    private func limitPctExceeded(_ alloc: AssetValue) -> Bool {
        guard let accountKey_ = accountKey,
              alloc.value > 0,
              let limitPctMap = document.context.accountUserAssetLimitMap[accountKey_],
              let limitPct = limitPctMap[alloc.assetKey],
              limitPct.isLess(than: targetValue(alloc) / totalValue, accuracy: epsilon)
        else { return false }

        return true
    }

    private var allocs: [AssetValue] {
        let zeroValue = [AssetValue(assetKey, 0)]
        switch cellType {
        case .rowTotal:
            guard let targetPct = ax.netAllocMap[assetKey] else { return zeroValue }
            return [AssetValue(assetKey, targetPct)]
        case .variableHeader:
            guard let targetPct = ax.variableAllocMap[assetKey] else { return zeroValue }
            return [AssetValue(assetKey, targetPct)]
        case .variable:
            guard let accountKey_ = accountKey,
                  let allocMap = document.allocationResult.accountAllocMap[accountKey_],
                  let targetPct = allocMap[assetKey]
            else { return zeroValue }
            return [AssetValue(assetKey, targetPct)]
        case .fixedHeader:
            guard let targetPct = ax.fixedAllocMap[assetKey] else { return zeroValue }
            return [AssetValue(assetKey, targetPct)]
        case .fixed:
            guard let accountKey_ = accountKey,
                  let allocMap = ax.fixedAccountAllocationMap[accountKey_],
                  let targetPct = allocMap[assetKey]
            else { return zeroValue } // need to return value so footer with orphan will show
            return [AssetValue(assetKey, targetPct)]
        }
    }

    private var isRollup: Bool {
        ax.isRollupAssets
    }

    private func targetValue(_ alloc: AssetValue) -> Double {
        switch cellType {
        case .rowTotal:
            return ax.netCombinedTotal * alloc.value
        case .variableHeader:
            return ax.netVariableTotal * alloc.value
        case .variable:
            guard let accountKey_ = accountKey,
                  let accountPV = ax.baseAccountPresentValueMap[accountKey_],
                  let allocMap = document.allocationResult.accountAllocMap[accountKey_],
                  let targetPct = allocMap[assetKey] else { return 0 }
            return accountPV * targetPct
        case .fixedHeader:
            return ax.netFixedAssetAmountMap[alloc.assetKey] ?? 0
        case .fixed:
            guard let accountKey_ = accountKey,
                  let amountMap = ax.fixedAllocatedMap[accountKey_],
                  let amount = amountMap[assetKey] else { return 0 }
            return amount
        }
    }

    // get present value of holdings, INCLUDING those closely related that will participate in allocation
    private func getHoldingsSummary(_ assetKey: AssetKey) -> HoldingsSummary {
        switch cellType {
        case .rowTotal: // , .rollup:
            return ax.rawHoldingsSummaryMap[assetKey] ?? HoldingsSummary()
        case .variableHeader:
            return ax.acceptedVariableSummaryMap[assetKey] ?? HoldingsSummary()
        case .variable:
            guard let accountKey_ = accountKey,
                  let activeHoldingsSummaryMap = ax.acceptedVariableAccountHoldingsSummaryMap[accountKey_],
                  let summary = activeHoldingsSummaryMap[assetKey]
            else { return HoldingsSummary() }
            return summary
        case .fixedHeader:
            return ax.acceptedFixedSummaryMap[assetKey] ?? HoldingsSummary()
        case .fixed:
            guard let accountKey_ = accountKey,
                  let activeHoldingsSummaryMap = ax.acceptedFixedAccountHoldingsSummaryMap[accountKey_],
                  let summary = activeHoldingsSummaryMap[assetKey]
            else { return HoldingsSummary() }
            return summary
        }
    }

    private var assetMap: AssetMap {
        if ax.assetMap.count > 0 {
            return ax.assetMap
        }
        return document.model.makeAssetMap()
    }
    
    private func getAssetClassTitle(_ assetKey: AssetKey) -> String {
        assetMap[assetKey]?.title ?? assetKey.assetNormID.capitalized
    }

    private var colorPair: (Color, Color) {
        getColor(colorCode)
    }

    private func getOrphanedAmount(_ assetKey: AssetKey) -> Double {
        guard let accountKey_ = accountKey else {
            return AssetValue.sumOf(ax.fixedOrphanedMap, assetKey: assetKey)
        }
        guard let amountMap = ax.fixedOrphanedMap[accountKey_],
              let amount = amountMap[assetKey],
              amount > 0
        else {
            return 0
        }
        return amount
    }
}
