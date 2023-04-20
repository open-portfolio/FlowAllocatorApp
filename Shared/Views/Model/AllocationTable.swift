//
//  AllocationTable.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Combine
import SwiftUI

import AllocData
import Detailer
import DetailerMenu
import Tabler

import FlowBase
import FlowUI

public struct AllocationTable: View {
    // MARK: - Parameters

    @Binding private var model: BaseModel
    private let ax: BaseContext
    private let strategy: MStrategy

    public init(model: Binding<BaseModel>, ax: BaseContext, strategy: MStrategy) {
        _model = model
        self.ax = ax
        self.strategy = strategy
    }

    // MARK: - Field Metadata

    private var gridItems: [GridItem] = [
        GridItem(.flexible(minimum: 190), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 20, maximum: 40), spacing: columnSpacing, alignment: .center),
        GridItem(.flexible(minimum: 70), spacing: columnSpacing, alignment: .trailing),
    ]

    // MARK: - Views

    typealias Context = TablerContext<MAllocation>

    private func header(_ ctx: Binding<Context>) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: flowColumnSpacing) {
            Sort.columnTitle("Asset Class", ctx, \.assetID)
                .onTapGesture { tablerSort(ctx, &model.allocations, \.assetID) { $0.assetKey < $1.assetKey } }
                .modifier(HeaderCell())
            Image(systemName: "lock.fill")
                .modifier(HeaderCell())
            Sort.columnTitle("Target", ctx, \.targetPct)
                .onTapGesture { tablerSort(ctx, &model.allocations, \.targetPct) { $0.targetPct < $1.targetPct } }
                .modifier(HeaderCell())
        }
    }

    private func brow(_ element: Binding<MAllocation>) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: flowColumnSpacing) {
            AssetTitleLabel(assetKey: element.wrappedValue.assetKey, assetMap: ax.assetMap, withID: true)
                .mpadding()
            Toggle(isOn: element.isLocked, label: { Text("Is Locked?") })
                .labelsHidden()
            PercentStepper(value: element.targetPct) {}
                .mpadding()
        }
        .modifier(EditDetailerContextMenu(element.wrappedValue,
                                          onDelete: deleteAction,
                                          onEdit: { toEdit = $0 }))
    }

    private func editDetail(ctx: DetailerContext<MAllocation>, element: Binding<MAllocation>) -> some View {
        let disableKey = ctx.originalID != newElement.primaryKey
        return Form {
            StrategyIDPicker(strategies: model.strategies.sorted(),
                             strategyID: element.strategyID)
            {
                Text("Strategy")
            }
            .disabled(strategy.primaryKey.isValid || disableKey)
            .validate(ctx, element, \.strategyID) { $0.count > 0 }

            AssetIDPicker(assets: filteredAssets(element.wrappedValue),
                          assetID: element.assetID)
            {
                Text("Asset Class")
            }
            .disabled(disableKey)
            .validate(ctx, element, \.assetID) { $0.count > 0 }

            Toggle(isOn: element.isLocked, label: { Text("Is Locked?") })
                .padding(.bottom, 5)

            PercentField("Limit Percent", value: element.targetPct)
                .validate(ctx, element, \.targetPct) { (0.0 ... 1.0).contains($0) }
        }
    }

    // MARK: - Locals

    private typealias Sort = TablerSort<MAllocation>
    private typealias DConfig = DetailerConfig<MAllocation>
    private typealias TConfig = TablerListConfig<MAllocation>

    private var dconfig: DConfig {
        DConfig(
            onDelete: deleteAction,
            onSave: saveAction,
            titler: { _ in "Allocation" }
        )
    }

    @State private var toEdit: MAllocation? = nil
    @State private var selected: MAllocation.ID? = nil
    @State private var hovered: MAllocation.ID? = nil

    public var body: some View {
        BaseModelTable(
            selected: $selected,
            toEdit: $toEdit,
            onAdd: { newElement },
            onEdit: editAction,
            onClear: clearAction,
            onExport: exportAction,
            onDelete: dconfig.onDelete,
            toolbarContent: toolbarContent
        ) {
            TablerList1B(
                .init(onMove: moveAction,
                      filter: { $0.strategyKey == strategy.primaryKey },
                      onHover: { if $1 { hovered = $0 } else { hovered = nil } }),
                header: header,
                row: brow,
                rowBackground: { MyRowBackground($0, hovered: hovered, selected: selected) },
                results: $model.allocations,
                selected: $selected
            )
        }
        .editDetailer(dconfig,
                      toEdit: $toEdit,
                      originalID: toEdit?.id,
                      detailContent: editDetail)
        .onChange(of: model.allocations) { _ in
            // ensure changing percentages, etc. causes grid to refresh

            NotificationCenter.default.post(name: .refreshContext, object: model.id)
        }
    }

    private func toolbarContent() -> AnyView {
        let sum = allocationSum
        let normie100percent = "100.00%"
        let normieEpsilon = 0.0001
        let isBal = sum.isEqual(to: 1.0, accuracy: normieEpsilon)
        let buttonText = isBal ? normie100percent : "\(sum.toPercent2()) → \(normie100percent)"
        return Button(action: { normalizeAllocations(controlIndex: nil) }) {
            Text(buttonText)
                .foregroundColor(isBal ? .gray : .yellow)
        }
        .disabled(isBal)
        .eraseToAnyView()
    }

    // MARK: - Helpers

    private var elementIndexes: IndexSet {
        let strategyKey = strategy.primaryKey
        return model.getAllocationIndexes(for: strategyKey)
    }

    private var allocationSum: Double {
        elementIndexes.reduce(0) { $0 + model.allocations[$1].targetPct }
    }

    private func normalizeAllocations(controlIndex: Int? = nil) {
        do {
            try MAllocation.normies(&model.allocations,
                                    indexSet: elementIndexes,
                                    controlIndex: controlIndex)
            refreshContext()
        } catch {
            print(error)
        }
    }

    private var assetMap: AssetMap {
        if ax.assetMap.count > 0 {
            return ax.assetMap
        }
        return model.makeAssetMap()
    }

    private func filteredAssets(_ allocation: MAllocation) -> [MAsset] {
        model.getFilteredAssets(strategyKey: strategy.primaryKey,
                                allocationKey: allocation.primaryKey)
    }

    // MARK: - Action Handlers

    private func refreshContext() {
        NotificationCenter.default.post(name: .refreshContext, object: model.id)
    }

    private func deleteAction(_ element: MAllocation) {
        model.delete(element)
        refreshContext()
    }

    private func saveAction(ctx: DetailerContext<MAllocation>, element: MAllocation) {
        let isNew = ctx.originalID == newElement.primaryKey
        model.save(element,
                   to: \.allocations,
                   originalID: isNew ? nil : ctx.originalID)
        refreshContext()
    }

    private var newElement: MAllocation {
        MAllocation(strategyID: strategy.strategyID, assetID: "", targetPct: nil, isLocked: nil)
    }

    private func editAction(_ id: MAllocation.ID?) -> MAllocation? {
        guard let _id = id else { return nil }
        return model.allocations.first(where: { $0.id == _id })
    }

    private func clearAction() {
        let strategyKey = strategy.primaryKey
        model.allocations.filter {
            $0.strategyKey == strategyKey
        }.forEach { model.delete($0) }

        refreshContext()
    }

    private func moveAction(from source: IndexSet, to destination: Int) {
        model.allocations.move(fromOffsets: source, toOffset: destination)
        refreshContext()
    }

    private func exportAction() {
        let finFormat = AllocFormat.CSV
        if let data = try? exportData(model.allocations, format: finFormat),
           let ext = finFormat.defaultFileExtension
        { // , activeOnly: isActive
            let name = MAllocation.entityName.plural.replacingOccurrences(of: " ", with: "-")
            #if os(macOS)
                NSSavePanel.saveData(data, name: name, ext: ext, completion: { _ in })
            #endif
        }
    }
}
