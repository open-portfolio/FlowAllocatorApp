//
//  CapTable.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//


import SwiftUI
import Detailer
import DetailerMenu
import AllocData
import Tabler
import FlowBase
import FlowUI

public struct CapTable: View {
    
    // MARK: - Parameters
    
    @Binding private var model: BaseModel
    private let ax: BaseContext
    private let account: MAccount
    
    public init(model: Binding<BaseModel>, ax: BaseContext, account: MAccount) {
        _model = model
        self.ax = ax
        self.account = account
    }
    
    // MARK: - Field Metadata
    
    private var gridItems: [GridItem] = [
        GridItem(.flexible(minimum: 190), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 70), spacing: columnSpacing, alignment: .leading),
    ]
    
    // MARK: - Views
    
    typealias Context = TablerContext<MCap>
    
    private func header(_ ctx: Binding<Context>) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: flowColumnSpacing) {
            Sort.columnTitle("Asset Class", ctx, \.assetID)
                .onTapGesture { tablerSort(ctx, &model.caps, \.assetID) { $0.assetKey < $1.assetKey } }
                .modifier(HeaderCell())
            Sort.columnTitle("Limit", ctx, \.limitPct)
                .onTapGesture { tablerSort(ctx, &model.caps, \.limitPct) { $0.limitPct < $1.limitPct } }
                .modifier(HeaderCell())
        }
    }
    
    private func row(_ element: MCap) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: flowColumnSpacing) {
            AssetTitleLabel(assetKey: element.assetKey, assetMap: ax.assetMap, withID: true)
                .mpadding()
            PercentLabel(value: element.limitPct)
                .mpadding()
       }
        .modifier(EditDetailerContextMenu(element, onDelete: deleteAction, onEdit: { toEdit = $0 }))
    }
    
    private func editDetail(ctx: DetailerContext<MCap>, element: Binding<MCap>) -> some View {
        let disableKey = ctx.originalID != newElement.primaryKey
        return Form {
            AccountIDPicker(accounts: model.accounts.sorted(),
                            accountID: element.accountID) {
                Text("Asset Class")
            }
            .disabled(account.primaryKey.isValid || disableKey)
            .validate(ctx, element, \.accountID) { $0.count > 0 }
            
            AssetIDPicker(assets: model.assets.sorted(),
                          assetID: element.assetID) {
                Text("Asset Class")
            }
            .disabled(disableKey)
            .validate(ctx, element, \.assetID) { $0.count > 0 }
            
            Section(footer: Text("* limit will be imposed where feasible")) {
                PercentField("Limit on Allocation", value: element.limitPct)
                    .validate(ctx, element, \.limitPct) { (0.0...1.0).contains($0) }
            }
        }
    }
    
    // MARK: - Locals
    
    private typealias Sort = TablerSort<MCap>
    private typealias DConfig = DetailerConfig<MCap>
    private typealias TConfig = TablerStackConfig<MCap>
    
    private var dconfig: DConfig {
        DConfig(
            onDelete: deleteAction,
            onSave: saveAction,
            titler: { _ in ("Cap") })
    }
    
    @State var toEdit: MCap? = nil
    @State var selected: MCap.ID? = nil
    @State var hovered: MCap.ID? = nil
    
    public var body: some View {
        BaseModelTable(
            selected: $selected,
            toEdit: $toEdit,
            onAdd: { newElement },
            onEdit: editAction,
            onClear: clearAction,
            onExport: exportAction,
            onDelete: dconfig.onDelete) {
                TablerStack1(
                    .init(onHover: { if $1 { hovered = $0 } else { hovered = nil } }),
                    header: header,
                    row: row,
                    rowBackground: { MyRowBackground($0, hovered: hovered, selected: selected) },
                    results: caps,
                    selected: $selected)
            }
            .editDetailer(dconfig,
                          toEdit: $toEdit,
                          originalID: toEdit?.id,
                          detailContent: editDetail)
            .onChange(of: model.caps) { _ in
                
                // ensure changing percentages, etc. causes grid to refresh
                
                NotificationCenter.default.post(name: .refreshContext, object: model.id)
            }
    }
    
    // MARK: - Helpers
    
    private var caps: [MCap] {
        model.caps.filter {
            $0.accountKey == account.primaryKey
        }
    }

    private var assetMap: AssetMap {
        if ax.assetMap.count > 0 {
            return ax.assetMap
        }
        return model.makeAssetMap()
    }
    
    private func filteredAssets(cap: MCap) -> [MAsset] {
        model.getFilteredAssets(accountKey: account.primaryKey, capKey: cap.primaryKey)
    }
    
    // MARK: - Action Handlers
    
    private func deleteAction(element: MCap) {
        model.delete(element)
    }
    
    private func editAction(_ id: MCap.ID?) -> MCap? {
        guard let _id = id else { return nil }
        return model.caps.first(where: { $0.id == _id })
    }
    
    private func saveAction(ctx: DetailerContext<MCap>, element: MCap) {
        let isNew = ctx.originalID == newElement.primaryKey
        model.save(element,
                   to: \.caps,
                   originalID: isNew ? nil : ctx.originalID)
    }
    
    private var newElement: MCap {
        MCap(accountID: account.accountID, assetID: "", limitPct: nil)
    }
    
    private func clearAction() {
        let accountKey = account.primaryKey
        model.caps.filter {
            $0.accountKey == accountKey
        }.forEach { model.delete($0) }
    }
    
    private func exportAction() {
        let finFormat = AllocFormat.CSV
        if let data = try? exportData(model.caps, format: finFormat),
           let ext = finFormat.defaultFileExtension
        {
            let name = MCap.entityName.plural.replacingOccurrences(of: " ", with: "-")
#if os(macOS)
            NSSavePanel.saveData(data, name: name, ext: ext, completion: { _ in })
#endif
        }
    }
}
