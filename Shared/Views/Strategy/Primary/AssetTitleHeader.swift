//
//  AssetTitleHeader.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import AllocData
import FlowAllocHigh
import FlowAllocLow
import FlowBase

import FlowUI

struct AssetTitleHeader: View {
    @Binding var document: AllocatDocument

    var body: some View {
        VStack(spacing: 2) {
            Text(formattedValue)
                .font(.largeTitle)
                .padding(.bottom, 4)

            Text(document.displaySettings.strategyMoneySelection.description)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(fill)
    }

    private var fill: some View {
        let color = isRollup ? document.accent.opacity(0.8) : Color.componentize(Color.gray).opacity(0.5)
        return MyColor.getBackgroundFill(color)
    }

    private var formattedValue: String {
        switch document.displaySettings.strategyMoneySelection {
        case .presentValue:
            return holdingsSummary.presentValue.toCurrency(style: .whole)
        case .gainLossAmount:
            return holdingsSummary.gainLoss.toCurrency(style: .whole, leadingPlus: true)
        case .gainLossPercent:
            return holdingsSummary.gainLossPercent?.toPercent1(leadingPlus: true) ?? ""
        case .orphaned:
            return orphanedSum.toCurrency(style: .whole)
        default:
            return ax.netCombinedTotal.toCurrency(style: .whole)
        }
    }

    private var ax: HighContext {
        document.context
    }

    private var isRollup: Bool {
        ax.isRollupAssets
    }

    private var holdingsSummary: HoldingsSummary {
        ax.mergedHoldingsSummary
    }

    private var orphanedSum: Double {
        AssetValue.sumOf(ax.fixedOrphanedMap)
    }
}
