//
//  ViewCommand.swift
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

import FlowAllocHigh
import FlowUI

struct ViewCommand: View {
    @FocusedBinding(\.document) private var document: AllocatDocument?

    let defaultEventModifier: EventModifiers = [.control, .command]

    var body: some View {
        Button(action: {
            document?.displaySettings.activeSidebarMenuKey = SidebarMenuIDs.activeStrategy.rawValue
        }, label: {
            Text("Active Strategy")
        })
        .keyboardShortcut(.return, modifiers: defaultEventModifier)

        Divider()

        summaryItems

        Divider()

        DataModelCommands(baseTableViewCommands: getBaseDataModelViewCommand(baseModelEntities),
                          onSelect: { document?.displaySettings.activeSidebarMenuKey = $0 })
    }

    @ViewBuilder
    var summaryItems: some View {
        Text("Holdings Summary")
        Button(action: {
            document?.displaySettings.activeSidebarMenuKey = SidebarMenuIDs.globalHoldings.rawValue
        }, label: {
            Text("All")
        })
        .keyboardShortcut("0", modifiers: defaultEventModifier)

        Button(action: {
            document?.displaySettings.activeSidebarMenuKey = SidebarMenuIDs.tradingAccountsSummary.rawValue
        }, label: {
            Text("Trading Accounts")
        })
        .keyboardShortcut("t", modifiers: defaultEventModifier)

        Button(action: {
            document?.displaySettings.activeSidebarMenuKey = SidebarMenuIDs.nonTradingAccountsSummary.rawValue
        }, label: {
            Text("Non-Trading Accounts")
        })
        .keyboardShortcut("n", modifiers: defaultEventModifier)
    }
}
