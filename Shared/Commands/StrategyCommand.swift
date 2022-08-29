//
//  StrategyCommand.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Combine
import SwiftUI

import KeyWindow

import AllocData

import FlowAllocHigh
import FlowUI

struct StrategyCommand: View {
    @KeyWindowValueBinding(AllocatDocument.self)
    var document: AllocatDocument?

    let defaultEventModifier: EventModifiers = [.command]
    let altEventModifier: EventModifiers = [.option, .command]

    var body: some View {
        ForEach(0 ..< strategies.count, id: \.self) { n in
            SettingsMenuItemKeyed(keyPath: \AllocatDocument.modelSettings.activeStrategyKey,
                                  keyToMatch: strategies[n].primaryKey,
                                  desc: strategies[n].titleID)
                .modifier(NumericKeyShortCutModifier(n: n + 1, modifiers: altEventModifier))
        }

        Divider()

        viewItems

        Divider()

        advancedItems
    }

    @ViewBuilder
    private var viewItems: some View {
        SettingsMenuItemBool(keyPath: \AllocatDocument.displaySettings.strategyShowVariable,
                             desc: "Trading Accounts")
            .keyboardShortcut("t", modifiers: defaultEventModifier)
        SettingsMenuItemBool(keyPath: \AllocatDocument.displaySettings.strategyShowFixed,
                             desc: "Non-Trading Accounts")
            .keyboardShortcut("u", modifiers: defaultEventModifier)

        Divider()

        Text("Cell Content")
        ForEach(MoneySelection.allCases, id: \.self) { item in
            SettingsMenuItemKeyed(keyPath: \AllocatDocument.displaySettings.strategyMoneySelection,
                                  keyToMatch: item,
                                  desc: item.fullDescription)
                .keyboardShortcut(item.keyboardShortcut, modifiers: defaultEventModifier)
        }

        Divider()

        SettingsMenuItemBool(keyPath: \AllocatDocument.displaySettings.strategyExpandBottom,
                             desc: "Result Details")
            .keyboardShortcut("y", modifiers: defaultEventModifier)
        SettingsMenuItemBool(keyPath: \AllocatDocument.displaySettings.showSecondary,
                             desc: "Inspector")
            .keyboardShortcut("0", modifiers: [.option, .command])

        Divider()
    }

    @ViewBuilder
    private var advancedItems: some View {
        Button(action: {
            document?.shuffleAction()
        }, label: {
            Text("Shuffle")
        })
            .keyboardShortcut("f", modifiers: defaultEventModifier)

        Divider()

        Text("Consolidation")

        SettingsMenuItemBool(keyPath: \AllocatDocument.modelSettings.rollupAssets,
                             desc: "Roll Up Assets")
            .keyboardShortcut("r", modifiers: defaultEventModifier)

        SettingsMenuItemBool(keyPath: \AllocatDocument.modelSettings.groupRelatedHoldings,
                             desc: "Group Related Holdings")
            .keyboardShortcut("g", modifiers: defaultEventModifier)

        SettingsMenuItemBool(keyPath: \AllocatDocument.modelSettings.reduceRebalance,
                             desc: "Reduce Rebalance")
            .keyboardShortcut("d", modifiers: defaultEventModifier)

        Divider()

        Text("Optimization")

        Button(action: {
            if let ax_ = ax {
                document?.optimize.startAction(ax: ax_, flowModes: OptimizeState.defaultFlowModes)
            }
        }, label: {
            Text("Begin Optimize")
        })
            .disabled(ax == nil)
            .keyboardShortcut("b", modifiers: defaultEventModifier)

        Button(action: {
            document?.optimizeAbort()
        }, label: {
            Text("Cancel")
        })
            .keyboardShortcut(".", modifiers: defaultEventModifier)
    }

    private var ax: HighContext? {
        document?.context
    }

    private var strategies: [MStrategy] {
        guard let document_ = document else { return [] }
        return document_.model.strategies.sorted()
    }
}
