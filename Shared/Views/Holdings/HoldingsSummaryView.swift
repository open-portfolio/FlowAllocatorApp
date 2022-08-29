//
//  HoldingsSummaryView.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//


import SwiftUI

import AllocData

import FlowAllocLow
import FlowBase
import FlowAllocHigh
import FlowUI

enum TabsHoldingTable: Int {
    case all
    case trading
    case nonTrading
    case rawTrading
    case rawNonTrading

    static let defaultTab = TabsHoldingTable.all
    static let storageKey = "HoldingsSummaryTab"
}

struct HoldingsSummaryView: View {
    @AppStorage(TabsHoldingTable.storageKey) var tab: TabsHoldingTable = .defaultTab
    
    @Binding var document: AllocatDocument
    
    var initialTab: TabsHoldingTable

    @State private var summarySelection: SummarySelection = .presentValue

    @State private var title = ""

    var body: some View {
        HStack {
            Text("\(title) — \(summarySelection.description)")
                .font(.title)

            Spacer()

            HelpButton(appName: "allocator", topicName: "holdingsSummary")
        }
        .padding(.horizontal)
        .padding(.top)

        TabView(selection: $tab) {
            HoldingsSummaryTable(model: document.model,
                                 ax: document.context,
                                 holdingsSummaryMap: ax.rawHoldingsSummaryMap,
                                 assetTickerSummaryMap: ax.rawAssetTickerHoldingsSummaryMap,
                                 summarySelection: $summarySelection)
                .tabItem { Text("All Accounts") }
                .tag(TabsHoldingTable.all)

            HoldingsSummaryTable(model: document.model,
                                 ax: document.context,
                                 holdingsSummaryMap: ax.mergedVariableSummaryMap,
                                 assetTickerSummaryMap: ax.mergedVariableAssetTickerHoldingsSummaryMap,
                                 summarySelection: $summarySelection)
                .tabItem { Text("Trading") }
                .tag(TabsHoldingTable.trading)

            if isGroupRelatedHoldings {
                HoldingsSummaryTable(model: document.model,
                                     ax: document.context,
                                     holdingsSummaryMap: ax.rawVariableSummaryMap,
                                     assetTickerSummaryMap: ax.rawVariableAssetTickerHoldingsSummaryMap,
                                     summarySelection: $summarySelection)
                    .tabItem { Text("Trading (base)") }
                    .tag(TabsHoldingTable.rawTrading)
            }

            HoldingsSummaryTable(model: document.model,
                                 ax: document.context,
                                 holdingsSummaryMap: ax.mergedFixedSummaryMap,
                                 assetTickerSummaryMap: ax.mergedFixedAssetTickerHoldingsSummaryMap,
                                 summarySelection: $summarySelection)
                .tabItem { Text("Non-Trading") }
                .tag(TabsHoldingTable.nonTrading)

            if isGroupRelatedHoldings {
                HoldingsSummaryTable(model: document.model,
                                     ax: document.context,
                                     holdingsSummaryMap: ax.rawFixedSummaryMap,
                                     assetTickerSummaryMap: ax.rawFixedAssetTickerHoldingsSummaryMap,
                                     summarySelection: $summarySelection)
                    .tabItem { Text("Non-Trading (base)") }
                    .tag(TabsHoldingTable.rawNonTrading)
            }
        }
        .padding(.horizontal)
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                ConsolidationToggles(document: $document)

                Spacer()

                SummarySelection.picker(summarySelection: $summarySelection)
                    .pickerStyle(SegmentedPickerStyle())

                Spacer()

                /* WEIRD - the following spacer would cause crash when navigating sidebar

                 [General] *** -[__NSArrayM objectAtIndex:]: index 9223372036854775806 beyond bounds [0 .. 1]
                 2021-06-17 10:50:30.918447-0600 Allocat[89777:5038781] [General] (
                         0   CoreFoundation                      0x000000018c935320 __exceptionPreprocess + 240
                         1   libobjc.A.dylib                     0x000000018c663c04 objc_exception_throw + 60
                         2   CoreFoundation                      0x000000018c9fc064 -[__NSCFString characterAtIndex:].cold.1 + 0
                         3   CoreFoundation                      0x000000018c855010 -[NSTaggedPointerString hash] + 0
                         4   AppKit                              0x000000018f9061e4 -[NSToolbarView _contentCenterOriginForCenterItem:layoutItems:leadingOffset:] + 264
                         5   AppKit                              0x000000018f18fe08 -[NSToolbarView _layoutDirtyItemViewersAndTileToolbar] + 4544
                         6   AppKit                              0x000000018f18b718 -[NSToolbarView _syncItemSetAndUpdateItemViewersWithSEL:setNeedsModeConfiguration:sizeToFit:setNeedsDisplay:updateKeyLoop:] + 176
                         7   AppKit                              0x000000018f179350 -[NSToolbar _insertItem:atIndex:notifyDelegate:notifyView:notifyFamilyAndUpdateDefaults:] + 200
                         8   AppKit                              0x000000018f179000 -[NSToolbar _insertNewItemWithItemIdentifier:atIndex:propertyListRepresentation:notifyFlags:] + 100

                 */
                // Spacer()
            }
        }
        .onChange(of: tab, perform: tabChangedAction)
        .onAppear {
            tab = initialTab
            tabChangedAction(newValue: initialTab)
        }
    }

    private var isGroupRelatedHoldings: Bool {
        ax.isGroupRelatedHoldings
    }

    private var ax: HighContext {
        document.context
    }

    private func tabChangedAction(newValue _: TabsHoldingTable) {
        switch tab {
        case .all:
            title = "Holdings Summary (active accounts)"
        case .trading:
            title = "Trading Holdings Summary"
        case .nonTrading:
            title = "Non-Trading Holdings Summary"
        case .rawTrading:
            title = "Trading Holdings Summary (base)"
        case .rawNonTrading:
            title = "Non-Trading Holdings Summary (base)"
        }
    }
}
