//
//  ContentView.swift
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
import FINporter

import FlowAllocHigh
import FlowAllocLow
import FlowBase
import FlowUI

// smallest is 1024 x 600
let minAppWidth: CGFloat = 1075 // NOTE may cause crash (when clicking on birdseye) if narrower than this
let minAppHeight: CGFloat = 695 // 640 // use 695 to generate 1280x790 screenshots  (TODO increase to 1280x800 target)
let idealAppWidth: CGFloat = 1440
let idealAppHeight: CGFloat = 800 // 900
let minSidebarWidth: CGFloat = 230

let baseModelEntities: [SidebarMenuIDs] = [
    .modelAccounts,
    .modelAssets,
    .modelHoldings,
    .modelSecurities,
    .modelStrategies,
    .modelTrackers,
    .modelTxns,
]

struct ContentView: View {
    @AppStorage(UserDefShared.userAgreedTermsAt.rawValue) var userAgreedTermsAt: String = ""
    @AppStorage(UserDefShared.timeZoneID.rawValue) var timeZoneID: String = ""
    @AppStorage(UserDefShared.defTimeOfDay.rawValue) var defTimeOfDay: TimeOfDayPicker.Vals = .useDefault

    @EnvironmentObject private var infoMessageStore: InfoMessageStore
    @Environment(\.undoManager) var undoManager

    // MARK: - Parameters

    @Binding var document: AllocatDocument

    // MARK: - Locals

    static let utiImportFile = "public.file-url"

    @State private var dragOver = false
    @State private var dropDelegate = URLDropDelegate(utiImportFile: ContentView.utiImportFile, milliseconds: 750)

    private let checkTermsPublisher = NotificationCenter.default.publisher(for: .checkTerms)
    private let importURLsPublisher = NotificationCenter.default.publisher(for: .importURLs) // uses ImportPayload
    private let refreshContextPublisher = NotificationCenter.default.publisher(for: .refreshContext)
    private let infoMessagePublisher = NotificationCenter.default.publisher(for: .infoMessage) // uses InfoMessagePayload

    var body: some View {
        if infoMessageStore.hasMessages(modelID: document.model.id) {
            InfoBanner(modelID: document.model.id, accent: document.accent)
                .frame(minHeight: 120, idealHeight: 250)
                .padding(.horizontal, 40)
        }

        NavigationView {
            SidebarView(topContent: topSidebarContent,
                        bottomContent: dataModelSection,
                        tradingHoldingsSummary: HoldingsSummaryView(document: $document, initialTab: .trading),
                        nonTradingHoldingsSummary: HoldingsSummaryView(document: $document, initialTab: .nonTrading),
                        strategySummary: strategySummary,
                        accountSummary: accountSummary,
                        model: $document.model,
                        ax: ax,
                        fill: document.accentFill,
                        assetColorMap: document.assetColorMap,
                        activeStrategyKey: $document.modelSettings.activeStrategyKey,
                        activeSidebarMenuKey: $document.displaySettings.activeSidebarMenuKey,
                        strategyAssetValues: strategyAssetValues,
                        fetchAssetValues: fetchAssetValues)

                // to provide access to key document in sidebar
                .keyWindow(AllocatDocument.self, $document)
                .frame(minWidth: minSidebarWidth, idealWidth: 250, maxWidth: 300)

            WelcomeView {
                GettingStarted(document: $document)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(windowBackgroundColor)
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .toolbar {
            ToolbarItem(placement: .navigation) { SidebarToggleButton() }
        }
        .modify {
            #if os(macOS)
                $0
                    .navigationSubtitle(quotedTitle)
                    .frame(minWidth: minAppWidth,
                           idealWidth: idealAppWidth,
                           maxWidth: .infinity,
                           minHeight: minAppHeight,
                           idealHeight: idealAppHeight,
                           maxHeight: .infinity)
            #else
                $0
            #endif
        }
        .border(dragOver ? document.accent : Color.clear)
        .onDrop(of: [ContentView.utiImportFile], delegate: dropDelegate)
        .onReceive(dropDelegate.debouncedURLs.didChange) {
            guard dropDelegate.debouncedURLs.value.count > 0 else { return }
            let urls = dropDelegate.purge()
            importAction(urls: urls)
        }
        .onReceive(importURLsPublisher) { payload in

            // import, but only for current document
            if let importPayLoad = payload.object as? ImportPayload,
               importPayLoad.modelID == document.model.id,
               importPayLoad.urls.count > 0
            {
                importAction(urls: importPayLoad.urls)
            }
        }
        .onReceive(refreshContextPublisher) { payload in

            // refresh, but only for current document
            if let modelID = payload.object as? UUID,
               modelID == document.model.id
            {
                refreshContextAction()
            }
        }
        .onReceive(infoMessagePublisher) { payload in
            if let msgPayload = payload.object as? InfoMessagePayload,
               msgPayload.modelID == document.model.id,
               msgPayload.messages.count > 0
            {
                infoMessageStore.add(contentsOf: msgPayload.messages, modelID: document.model.id)
            }
        }
        .onChange(of: document.model) { _ in
            guard userAcknowledgedTerms else { return }
            refreshContextAction()
        }
        .onChange(of: document.modelSettings) { _ in
            guard userAcknowledgedTerms else { return }
            refreshContextAction()
        }
        .onAppear {
            guard userAcknowledgedTerms else { return }
            refreshContextAction()
        }

        BaseSheets()
    }

    private var topSidebarContent: some View {
        AllocatSidebar(document: $document,
                       strategiedHoldingsSummary: strategiedHoldingsSummary,
                       isEmpty: isEmpty)
    }

    private var strategiedHoldingsSummary: some View {
        HoldingsSummaryView(document: $document, initialTab: .all)
    }

    private func strategySummary(strategy: MStrategy) -> some View {
        StrategySummary(document: $document, strategy: strategy)
    }

    private func accountSummary(account: MAccount) -> some View {
        AccountSummary(document: $document,
                       account: account)
    }

    private var windowBackgroundColor: Color {
        #if os(macOS)
            Color(.windowBackgroundColor)
        #else
            Color.secondary
        #endif
    }

    // MARK: - Data Model Helper Views

    private var dataModelSection: some View {
        SidebarDataModelSection(model: $document.model,
                                ax: ax,
                                activeSidebarMenuKey: $document.displaySettings.activeSidebarMenuKey,
                                baseModelEntities: baseModelEntities,
                                fill: document.accentFill,
                                warningCounts: warningCounts,
                                showGainLoss: true,
                                warnMissingSharePrice: false)
    }

    private var warningCounts: [String: Int] {
        var map = [String: Int]()
        if case let count = ax.activeTickersMissingSomething.count,
           count > 0
        {
            map[SidebarMenuIDs.modelSecurities.rawValue] = count
        }
        if case let count = ax.missingRealizedGainsTxns.count,
           count > 0
        {
            map[SidebarMenuIDs.modelTxns.rawValue] = count
        }
        return map
    }

    // MARK: - Properties

    private var ax: HighContext {
        document.context
    }

    private var isEmpty: Bool {
        ax.rawHoldingsSummary.presentValue == 0
    }

    private var userAcknowledgedTerms: Bool {
        userAgreedTermsAt.trimmingCharacters(in: .whitespaces).count > 0
    }

    private var quotedTitle: String {
        guard document.modelSettings.activeStrategyKey.isValid,
              let strategy = ax.strategyMap[document.modelSettings.activeStrategyKey] else { return "" }
        return "‘\(strategy.titleID)’"
    }

    // MARK: - Actions

    private func fetchAssetValues(_ accountKey: AccountKey) -> [AssetValue] {
        ax.accountHoldingsAssetValuesMap[accountKey] ?? []
    }

    private func refreshContextAction() {
        document.refreshContext(strategyKey: document.modelSettings.activeStrategyKey)
    }

    private func importAction(urls: [URL]) {
        guard urls.count > 0 else { return }
        let timeZone = TimeZone(identifier: timeZoneID) ?? TimeZone.current
        let normTimeOfDay: String? = BaseModel.normalizeTimeOfDay(defTimeOfDay.rawValue)
        let results = document.model.importData(urls: urls, timeZone: timeZone, defTimeOfDay: normTimeOfDay)

        infoMessageStore.displayImportResults(modelID: document.model.id, results)

        refreshContextAction()
    }

    // MARK: - Helpers

    private var strategyAssetValues: [AssetValue] {
        guard document.modelSettings.activeStrategyKey.isValid else { return [] }
        let netAllocMap = ax.netAllocMap
        guard !netAllocMap.isEmpty else { return [] }
        let assetKeys = document.displaySettings.params.assetKeys
        guard !assetKeys.isEmpty else { return [] }
        return AssetValue.getAssetValues(from: netAllocMap, orderBy: assetKeys)
    }
}
