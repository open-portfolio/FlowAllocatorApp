//
//  OptimizeTable.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import SwiftPriorityQueue
import Tabler

import FlowAllocHigh
import FlowAllocLow
import FlowBase
import FlowUI
import FlowViz

typealias SetResult = (TabsOptimize, HighResult) -> Void

struct OptimizeTable: View {
    @Binding private var document: AllocatDocument
    @Binding private var sorts: [ResultSort]
    private var results: [HighResult]
    private var assetValueMap: AssetValueMap
    private var onSetResult: SetResult
    private var onConfigChange: () -> Void
    private var tab: TabsOptimize

    public init(document: Binding<AllocatDocument>,
                sorts: Binding<[ResultSort]>,
                results: [HighResult],
                assetValueMap: AssetValueMap,
                onSetResult: @escaping SetResult,
                onConfigChange: @escaping () -> Void,
                tab: TabsOptimize)
    {
        _document = document
        _sorts = sorts
        self.results = results
        self.assetValueMap = assetValueMap
        self.onSetResult = onSetResult
        self.onConfigChange = onConfigChange
        self.tab = tab
    }

    @State var selected: HighResult.ID? = nil
    @State var hovered: HighResult.ID? = nil

    var body: some View {
        VStack {
            HStack {
                sortTitle
                    .font(.title2)
                Spacer()
                myMenu
            }
            .padding(.horizontal)
            .lineLimit(1)

            TablerList1(.init(onHover: { if $1 { hovered = $0 } else { hovered = nil } }),
                        header: header,
                        row: row,
                        rowBackground: { MyRowBackground($0, hovered: hovered, selected: selected) },
                        results: results,
                        selected: $selected)
                .onChange(of: selected) { nuID in
                    guard let result = results.first(where: { $0.id == nuID }) else { return }
                    onSetResult(tab, result)
                }
        }
    }

    private var sortTitle: some View {
        guard let firstSort = sorts.first else { return Text("Assign a column").font(.title) }
        let attribute = ResultSort.getTitle(firstSort.attribute)
        let direction = ResultSort.getDirection(firstSort.direction, compact: true)
        return Text(attribute) +
            Text(" (\(direction))").foregroundColor(.secondary)
    }

    private var myMenu: some View {
        Menu {
            ForEach(ResultSort.Attribute.allCases, id: \.self) { attribute in
                Button(action: { attributeAction(attribute) }, label: {
                    Text("\(isActiveSort(attribute) ? "✓" : "   ") \(ResultSort.getTitle(attribute))")
                })
            }
        }
        label: {
            Image(systemName: "ellipsis.circle")
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .frame(width: 40)
    }

    private func header(ctx _: Binding<TablerContext<HighResult>>) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: flowColumnSpacing) {
            ForEach(sorts, id: \.self) { sort in
                OptimizeHeaderCell(document: $document, item: sort,
                                   sortIndex: getSortIndex(sort.attribute) ?? 0,
                                   key: "OPTIMIZE",
                                   onMove: sortMoveAction,
                                   onDirection: sortDirectionAction)
            }
        }
    }

    private func row(_ result: HighResult) -> some View {
        VStack {
            LazyVGrid(columns: gridItems, alignment: .leading, spacing: flowColumnSpacing) {
                ForEach(sorts, id: \.self) { sort in
                    MonoCell {
                        Group {
                            switch sort.attribute {
                            case .netTaxGains:
                                currencyLabel(value: result.netTaxGains)
                            case .absTaxGains:
                                currencyLabel(value: result.absTaxGains)
                            case .saleVolume:
                                currencyLabel(value: result.saleVolume)
                            case .transactionCount:
                                Text("\(result.transactionCount)")
                            case .flowMode:
                                Text("\(result.flowMode.toPercent1())")
                            case .wash:
                                currencyLabel(value: result.washAmount)
                            }
                        }
                        .lineLimit(1)
                    }
                }
            }
            VizBarView(getTargetAllocs(result.assetKeys))
                .shadow(radius: 1, x: 2, y: 2)
        }
    }

    // MARK: - Helpers

    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 100)), count: sorts.count)
    }

    private func getTargetAllocs(_ assetKeys: [AssetKey]) -> [VizSlice] {
        let av = AssetValue.getAssetValues(from: assetValueMap, orderBy: assetKeys)
        let ta = av.map { VizSlice($0.value, document.assetColorMap[$0.assetKey]?.1 ?? Color.gray) }
        guard ta.count > 0 else { return [VizSlice(1.0, Color.gray)] }
        return ta
    }

    private func currencyLabel(value: Double, ifZero: String? = nil) -> some View {
        CurrencyLabel(value: value, ifZero: ifZero, style: .whole)
            .padding(.horizontal, 5)
            .frame(maxWidth: .infinity)
    }

    private func isActiveSort(_ attribute: ResultSort.Attribute) -> Bool {
        getSortIndex(attribute) != nil
    }

    private func getSortIndex(_ attribute: ResultSort.Attribute) -> Int? {
        guard let index = sorts.firstIndex(where: { $0.attribute == attribute })
        else { return nil }
        return index
    }

    private func attributeAction(_ attribute: ResultSort.Attribute) {
        if let index = getSortIndex(attribute) {
            // it's set, so we'll unset
            sorts.remove(at: index)
        } else {
            // it wasn't set, so we'll set it fresh
            sorts.append(ResultSort(attribute, .ascending))
        }

        onConfigChange()
    }

    private func sortMoveAction(fromIdx: Int, toIdx: Int) {
        guard fromIdx != toIdx else { return }
        sorts.move(at: fromIdx, to: toIdx)
        // to reflect new settings
        onConfigChange()
    }

    private func sortDirectionAction(_ attribute: ResultSort.Attribute, _ nuDirection: ResultSort.Direction) {
        if let index = getSortIndex(attribute),
           sorts[index].direction != nuDirection
        {
            sorts[index].direction = nuDirection
            // to reflect new settings
            onConfigChange()
        }
    }
}
