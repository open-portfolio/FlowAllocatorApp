//
//  RebalanceLiquidateCell.swift
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

struct RebalanceLiquidateCell: View {
    @Binding var document: AllocatDocument

    var account: MAccount
    var sale: Sale

    var body: some View {
        BaseRebalanceCell(document: $document,
                          title: "Sell",
                          amount: sale.proceeds,
                          assetKey: sale.assetKey,
                          rowContent: rowContent)
    }

    @ViewBuilder
    private func rowContent() -> some View {
        // Exclude holdings that haven't been flagged for liquidation
        // (they'll still show up in the Apply view, where user can select them)
        ForEach(liquidateHoldings, id: \.self) { lh in
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "trash.fill")
                LiquidateLabel(document: $document, liquidateHolding: lh)
            }
        }

        let netGainLoss = sale.netGainLoss
        if abs(netGainLoss) > 1 {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "plus.slash.minus")
                Text("Net: \(netGainLoss.toCurrency(style: .compact, leadingPlus: true)) \(netGainLoss > 0 ? "(gain)" : "(loss)")")
            }
        }

        let _washAmount = saleWashAmount
        if _washAmount != 0 {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "w.square.fill")
                Text("Wash: \(_washAmount.toCurrency(style: .whole))")
            }
        }
    }

    // MARK: - Properties

    private var ax: HighContext {
        document.context
    }

    private var saleWashAmount: Double {
        sale.getWashAmount(recentPurchasesMap: ax.recentPurchasesMap,
                           securityMap: ax.securityMap)
    }

    // NOTE what about sale washes that are byproduct of from today's purchases?
    // That SHOULD be covered by purchase warning in other account.
    // See losingTaxableSales

    private var liquidateHoldings: [LiquidateHolding] {
        sale.liquidateHoldings.filter { ($0.fractionalValue ?? 0) > 0 }
    }
}
