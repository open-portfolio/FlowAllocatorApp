//
//  GettingStarted.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import FlowAllocHigh
import FlowUI
import FlowBase
import AllocData

struct GettingStarted: View {
    @Binding var document: AllocatDocument

    var body: some View {
        ScrollView {
            GroupBox(label: Text("Getting Started")) {
                VStack(alignment: .leading) {
                    Group {
                        Text("First steps to rebalancing your portfolio:")
                        myText(1, "Create (or import) your accounts")
                        myText(2, "Create (or import) holdings for those accounts")
                        myText(3, "Ensure each held security is priced and assigned to an asset class")
                        myText(4, "Create (or import) your strategy, with allocations to each asset class")
                        myText(5, "Assign accounts to your strategy, and configure each as ‘trading’")
                        myText(6, "Start exploring!")
                    }
                    .font(.title2)
                    .padding()
                }
            }
            
            if document.model.accounts.count == 0 {
                HStack {
                    Text("Or if you just want to explore with fake data...")
                        .font(.title2)
                    Button(action: randomPortfolioAction, label: {
                        Text("Generate Random Portfolio")
                    })
                }
                .padding()
            }
        }
    }
    
    private func myText(_ n: Int, _ suffix: String) -> some View {
        WelcomeNumberedLabel(n, fill: document.accentFill) { Text(suffix) }
    }

    private func randomPortfolioAction() {
        do {
            let populator = BasePopulator(&document.model)
            try populator.populateRandom(&document.model)
            document.modelSettings.activeStrategyKey = document.model.strategies.randomElement()?.primaryKey ?? MStrategy.emptyKey
            document.displaySettings.params.flowMode = Double.random(in: 0 ... 1)
            document.displaySettings.activeSidebarMenuKey = SidebarMenuIDs.activeStrategy.rawValue
        } catch {
            print(error)
        }
    }
}
