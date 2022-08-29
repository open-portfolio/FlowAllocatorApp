//
//  SecondarySummary.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import AllocData

import FlowBase
import FlowAllocHigh
import FlowUI

enum TabsSecondaryStrategy: Int {
    case rebalance
    case optimize
    case allocation
    case consolidation

    static let defaultTab = TabsSecondaryStrategy.rebalance
    static let storageKey = "SecondaryStrategyTab"
}

struct SecondaryStrategy: View {
    @AppStorage(TabsSecondaryStrategy.storageKey) var tab: TabsSecondaryStrategy = .defaultTab

    @Binding var document: AllocatDocument
    var strategy: MStrategy

    var body: some View {
        TabView(selection: $tab) {
            RebalanceView(document: $document,
                          strategy: strategy)
                .tabItem { Text("Rebalance") }
                .tag(TabsSecondaryStrategy.rebalance)
            AllocationTable(model: $document.model, ax: document.context, strategy: strategy)
                .tabItem { Text("Allocation") }
                .tag(TabsSecondaryStrategy.allocation)
            OptimizeView(document: $document,
                         strategy: strategy,
                         optimize: document.optimize)
                .tabItem { Text("Optimize") }
                .tag(TabsSecondaryStrategy.optimize)
            ConsolidationView(document: $document, strategy: strategy)
                .tabItem { Text("Consolidate") }
                .tag(TabsSecondaryStrategy.consolidation)
        }
        .padding(.top, 5)
    }

    // MARK: - Properties
    
    private var allocs: [MAllocation] {
        document.model.allocations.filter { $0.strategyKey == strategy.primaryKey }
    }
}
