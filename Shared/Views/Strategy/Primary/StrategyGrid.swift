//
//  StrategyGrid.swift
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

struct StrategyGrid: View {
    // MARK: - Parameters

    @Binding var document: AllocatDocument
    var strategy: MStrategy

    // MARK: - Locals

    @State private var hoveredIndex: Int? = nil

    // MARK: - Views

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading) { // .leading needed to keep list from centering when squeezed horizontally
                headerView(geo) // for iOS needs to be outside list for account DnD to work
                    .frame(maxHeight: 120)
                    .padding(.leading, 16)
                    .padding(.trailing, 15)
                    .padding(.bottom, -10) // TODO: can we get rid of this?
                List {
                    ForEach(0 ..< table.rows.count, id: \.self) { n in
                        let isMovable = n < assetKeyCount

                        rowView(n, geo, document.allocationTable.rows[n], isMovable: isMovable)
                            .frame(maxWidth: .infinity)
                            .moveDisabled(!isMovable)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: rowSpacing, trailing: 0))

                            // hovering changes the background, slightly
                            .onHover { if $0 { hoveredIndex = n } }
                            .background(hoveredIndex == n ? Color.accentColor.opacity(0.1) : Color.clear)
                    }
                    .onMove(perform: rowMoveAction)

                    if let footNote_ = footNote {
                        HStack {
                            Spacer()
                            Text(footNote_)
                                .font(.caption)
                                .padding(.trailing)
                        }
                        .moveDisabled(true)
                    }
                }
            }
            .ignoresSafeArea(.container, edges: .trailing) // needed so there's no right margin when right sidebar is crowding grid
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func headerView(_ geo: GeometryProxy) -> some View {
        HStack(spacing: categorySpacing) {
            // COLUMN assets
            GridCategory(title: strategy.titleID, color: document.accent) {
                AssetTitleHeader(document: $document)
            }
            .frame(width: firstColumnWidth(geo))
            .frame(maxHeight: .infinity)

            // COLUMN variable Allocation
            if showVariable {
                GridCategory(title: "Trading Accounts", color: nil) {
                    CategoryTitleHeader(document: $document,
                                        bg: strategyTradingColor,
                                        cells: table.headerCells,
                                        amount: ax.netVariableTotal,
                                        orphanedAmount: 0, // no variable orphans
                                        holdingsSummary: ax.mergedVariableHoldingsSummary,
                                        dragKey: "VARIABLE",
                                        moveAction: variableAccountMoveAction,
                                        categoryColumnWidth: categoryColumnWidth(geo),
                                        valueColumnWidth: valueColumnWidth(geo),
                                        columnSpacing: columnSpacing)
                }
            }

            // COLUMN fixed allocation
            if showFixed {
                GridCategory(title: "Non-Trading Accounts", color: nil) {
                    CategoryTitleHeader(document: $document,
                                        bg: strategyNonTradingColor,
                                        cells: table.fixedHeaderCells,
                                        amount: ax.netFixedTotal,
                                        orphanedAmount: orphanedSum,
                                        holdingsSummary: ax.mergedFixedHoldingsSummary,
                                        dragKey: "FIXED",
                                        moveAction: fixedAccountMoveAction,
                                        categoryColumnWidth: categoryColumnWidth(geo),
                                        valueColumnWidth: valueColumnWidth(geo),
                                        columnSpacing: columnSpacing)
                }
            }

            dragControl(isMovable: false)
                .opacity(0) // .hidden()
        }
    }

    private func rowView(_: Int, _ geo: GeometryProxy, _ row: HighRow, isMovable: Bool) -> some View {
        HStack(spacing: categorySpacing) {
            // COLUMN assets
            StrategyCell(document: $document,
                         cellType: .rowTotal,
                         assetKey: row.assetKey,
                         accountKey: nil,
                         colorCode: row.colorCode,
                         moneySelection: document.displaySettings.strategyMoneySelection,
                         assetClassPrefix: true,
                         categoryColumnWidth: categoryColumnWidth(geo))
                .frame(width: firstColumnWidth(geo))

            // COLUMN variable Allocation
            if showVariable {
                CategoryRow(document: $document,
                            row: row,
                            headerCellType: .variableHeader,
                            valueCellType: .variable,
                            cells: row.cells,
                            categoryColumnWidth: categoryColumnWidth(geo),
                            valueColumnWidth: valueColumnWidth(geo),
                            columnSpacing: columnSpacing)
            }

            // COLUMN fixed allocation
            if showFixed {
                CategoryRow(document: $document,
                            row: row,
                            headerCellType: .fixedHeader,
                            valueCellType: .fixed,
                            cells: row.fixedCells,
                            categoryColumnWidth: categoryColumnWidth(geo),
                            valueColumnWidth: valueColumnWidth(geo),
                            columnSpacing: columnSpacing)
            }

            dragControl(isMovable: isMovable)
        }
    }

    private func dragControl(isMovable: Bool) -> some View {
        Image(systemName: "line.horizontal.3")
            .opacity(isMovable ? 1.0 : 0.1)
            .frame(width: dragControlWidth, alignment: .center)
    }

    private var strategyTradingColor: Color {
        accent.opacity(0.8)
    }

    private var strategyNonTradingColor: Color {
        accent.opacity(0.6)
    }

    private var accent: Color {
        document.accent
    }

    // MARK: - Geo Properties

    private let marginWidth: CGFloat = 30 // 34
    private let minimumFirstColumnWidth: CGFloat = 250
    private let minimumCategoryColumnWidth: CGFloat = 80
    private let minimumValueColumnWidth: CGFloat = 110
    private let columnSpacing: CGFloat = 3
    private let categorySpacing: CGFloat = 8
    private let dragControlWidth: CGFloat = 20
    private let rowSpacing: CGFloat = 2
    private let headerSpacing: CGFloat = 3

    private func firstColumnWidth(_ geo: GeometryProxy) -> CGFloat {
        minimumFirstColumnWidth * horizontalScaleFactor(geo)
    }

    private func categoryColumnWidth(_ geo: GeometryProxy) -> CGFloat {
        minimumCategoryColumnWidth * horizontalScaleFactor(geo)
    }

    private func valueColumnWidth(_ geo: GeometryProxy) -> CGFloat {
        minimumValueColumnWidth * horizontalScaleFactor(geo)
    }

    private func getMinimumElasticCategoryWidth(columnCount: Int) -> CGFloat {
        minimumCategoryColumnWidth + (minimumValueColumnWidth * CGFloat(columnCount))
    }

    private func getMinimumFixedCategoryWidth(columnCount: Int) -> CGFloat {
        columnSpacing * CGFloat(columnCount)
    }

    private var minimumElasticWidth: CGFloat {
        minimumFirstColumnWidth +
            (showVariable
                ? getMinimumElasticCategoryWidth(columnCount: table.headerCells.count)
                : 0) +
            (showFixed
                ? getMinimumElasticCategoryWidth(columnCount: table.fixedHeaderCells.count)
                : 0)
    }

    private var minimumStaticWidth: CGFloat {
        marginWidth +
            // first column here
            categorySpacing +
            (showVariable
                ? getMinimumFixedCategoryWidth(columnCount: table.headerCells.count) + categorySpacing
                : 0) +
            (showFixed
                ? getMinimumFixedCategoryWidth(columnCount: table.fixedHeaderCells.count) + categorySpacing
                : 0) +
            dragControlWidth
    }

    private func horizontalScaleFactor(_ geo: GeometryProxy) -> CGFloat {
        let availableWidth = geo.size.width
        guard availableWidth > 0 else { return 1.0 }
        let netElasticWidth = max(0, availableWidth - minimumStaticWidth)
        let factor = max(1.0, netElasticWidth / minimumElasticWidth)
        return factor
    }

    // MARK: - Properties

    private var assetKeyCount: Int {
        document.displaySettings.params.assetKeys.count
    }

    private var isRollup: Bool {
        ax.isRollupAssets
    }

    private var orphanedSum: Double {
        AssetValue.sumOf(ax.fixedOrphanedMap)
    }

    private var ax: HighContext {
        document.context
    }

    private var table: HighStrategyTable {
        document.allocationTable
    }

    private var showVariable: Bool {
        document.displaySettings.strategyShowVariable && table.headerCells.count > 0
    }

    private var showFixed: Bool {
        document.displaySettings.strategyShowFixed && table.fixedHeaderCells.count > 0
    }

    private var title: String {
        document.displaySettings.strategyMoneySelection.description
    }

    private var footNote: String? {
        let msg = "* may include holdings in other asset classes"
        return document.displaySettings.strategyShowFixed && document.displaySettings.strategyMoneySelection == .orphaned ? msg : nil
    }

    private var activeHoldingsSummaryMap: AssetHoldingsSummaryMap {
        ax.rawHoldingsSummaryMap
    }

    // MARK: - Action handlers

    private func rowMoveAction(from source: IndexSet, to destination: Int) {
        let count = document.displaySettings.params.assetKeys.count
        guard destination <= count else {
            // print("can't move to destination \(destination)")
            return
        }
        document.displaySettings.params.assetKeys.move(fromOffsets: source, toOffset: destination)

        document.refreshHighResult()
    }

    private func variableAccountMoveAction(fromIdx: Int, toIdx: Int) {
        document.displaySettings.params.accountKeys.move(at: fromIdx, to: toIdx)
        document.refreshHighResult()
    }

    private func fixedAccountMoveAction(fromIdx: Int, toIdx: Int) {
        document.displaySettings.params.fixedAccountKeys.move(at: fromIdx, to: toIdx)
        document.refreshHighResult()
    }
}
