//
//  CategoryRow.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import FlowAllocHigh
import FlowAllocLow
import FlowBase

import AllocData

struct CategoryRow: View {
    @Binding var document: AllocatDocument
    var row: HighRow
    var headerCellType: StrategyCell.CellType
    var valueCellType: StrategyCell.CellType
    var cells: [BaseItem]
    var categoryColumnWidth: CGFloat
    var valueColumnWidth: CGFloat
    var columnSpacing: CGFloat

    var body: some View {
        HStack(spacing: columnSpacing) {
            StrategyCell(document: $document,
                         cellType: headerCellType,
                         assetKey: row.assetKey,
                         accountKey: nil,
                         colorCode: row.colorCode,
                         moneySelection: document.displaySettings.strategyMoneySelection,
                         assetClassPrefix: false,
                         categoryColumnWidth: categoryColumnWidth)
                .frame(width: categoryColumnWidth)

            ForEach(cells) { allocation in
                StrategyCell(document: $document, cellType: valueCellType,
                             assetKey: row.assetKey,
                             accountKey: allocation.accountKey,
                             colorCode: row.colorCode,
                             moneySelection: document.displaySettings.strategyMoneySelection,
                             assetClassPrefix: false,
                             categoryColumnWidth: categoryColumnWidth)
                    .frame(width: valueColumnWidth)
            }
        }
    }
}
