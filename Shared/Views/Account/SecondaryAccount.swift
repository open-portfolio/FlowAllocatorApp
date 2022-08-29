//
//  SecondaryAccount.swift
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

enum TabsAccount: Int {
    case rebalance
    case holdings
    case caps
    case transactions

    static let defaultTab = TabsAccount.holdings
    static let storageKey = "SecondaryAccountTab"
}

struct SecondaryAccount: View {
    @AppStorage(TabsAccount.storageKey) var tab: TabsAccount = .defaultTab
    
    @Binding var document: AllocatDocument

    // MARK: - Parameters

    var account: MAccount

    var body: some View {
        TabView(selection: $tab) {
            if account.canTrade {
                AccountRebalanceView(document: $document, account: account)
                    .tabItem { Text("Rebalance") }
                    .tag(TabsAccount.rebalance)
            }

            HoldingTable(model: $document.model, ax: document.context, account: account)
                .tabItem { Text("Holdings") }
                .tag(TabsAccount.holdings)

            CapTable(model: $document.model, ax: document.context, account: account)
                .tabItem { Text("Caps") }
                .tag(TabsAccount.caps)

            TransactionTable(model: $document.model, ax: document.context, account: account, showGainLoss: true, warnMissingSharePrice: false)
                .tabItem { Text("Transactions") }
                .tag(TabsAccount.transactions)
        }
    }
}
