//
//  CategoryTitleHeader.swift
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

struct CategoryTitleHeader: View {
    @Binding var document: AllocatDocument

    var bg: Color
    var cells: [BaseColumnHeader]
    var amount: Double
    var orphanedAmount: Double
    var holdingsSummary: HoldingsSummary
    var dragKey: String
    var moveAction: (Int, Int) -> Void
    var categoryColumnWidth: CGFloat
    var valueColumnWidth: CGFloat
    var columnSpacing: CGFloat

    var body: some View {
        HStack(spacing: columnSpacing) {
            Text(formattedValue)
                .font(.headline)
                .frame(width: categoryColumnWidth)
                .frame(maxHeight: .infinity)
                .background(fill)

            ForEach(0 ..< cells.count, id: \.self) { n in
                AccountHeaderCell(document: $document,
                                  item: cells[n],
                                  accountIndex: n,
                                  key: dragKey,
                                  onMove: moveAction,
                                  moneySelection: $document.displaySettings.strategyMoneySelection,
                                  bgFill: accountFill)
                    .frame(width: valueColumnWidth)
            }
        }
        .foregroundColor(controlTextColor)
        .frame(maxHeight: .infinity)
    }

    private var fill: some View {
        MyColor.getBackgroundFill(bg)
    }

    private var accountFill: AnyView {
        MyColor.getBackgroundFill(bg.opacity(0.5))
    }

    private var controlTextColor: Color {
        #if os(macOS)
            Color(.controlTextColor)
        #else
            Color.primary
        #endif
    }

    private var formattedValue: String {
        switch document.displaySettings.strategyMoneySelection {
        case .percentOfAccount, .percentOfStrategy:
            return fractionPercent.toPercent1(leadingPlus: false)
        case .amountOfStrategy:
            return amount.toCurrency(style: .whole)
        case .presentValue:
            return holdingsSummary.presentValue.toCurrency(style: .whole)
        case .gainLossAmount:
            return holdingsSummary.gainLoss.toCurrency(style: .whole, leadingPlus: true)
        case .gainLossPercent:
            return holdingsSummary.gainLossPercent?.toPercent1(leadingPlus: true) ?? ""
        case .orphaned:
            let oa = orphanedAmount
            if oa > 0 {
                return "\(orphanedAmount.toCurrency(style: .whole))*"
            } else {
                return ""
            }
        }
    }

    private var fractionPercent: Double {
        let combined = document.context.netCombinedTotal
        guard combined > 0 else { return 0 }
        return amount / combined
    }
}
