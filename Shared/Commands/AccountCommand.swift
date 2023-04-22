//
//  AccountCommand.swift
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

struct AccountCommand: View {
    @FocusedBinding(\.document) private var document: AllocatDocument?

    let defaultEventModifier: EventModifiers = [.control, .option] // [.shift, .option, .command]
    let altEventModifier: EventModifiers = [.option, .command]

    var body: some View {
        if let accounts = document?.activeAccounts, accounts.count > 0 {
            ForEach(0 ..< accounts.count, id: \.self) { n in
                SettingsMenuItemKeyed(keyPath: \AllocatDocument.displaySettings.activeSidebarMenuKey,
                                      keyToMatch: accounts[n].primaryKey.accountNormID,
                                      desc: accounts[n].titleID)
                    .modifier(NumericKeyShortCutModifier(n: n + 1, modifiers: defaultEventModifier))
            }
        }

        Divider()

        SettingsMenuItemBool(keyPath: \AllocatDocument.displaySettings.showSecondary,
                             desc: "Inspector")
            .keyboardShortcut("0", modifiers: altEventModifier)
    }
}
