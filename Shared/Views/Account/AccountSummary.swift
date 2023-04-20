//
//  AccountSummary.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import AllocData

import FlowAllocHigh
import FlowAllocLow
import FlowBase
import FlowUI

struct AccountSummary: View {
    // MARK: - Parameters

    @Binding var document: AllocatDocument
    var account: MAccount

    // MARK: - Locals

    @State private var summarySelection: SummarySelection = .presentValue

    private var primary: some View {
        PrimaryAccount(document: $document,
                       account: account,
                       summarySelection: $summarySelection)
            .frame(minWidth: 600, idealWidth: 800, maxWidth: .infinity, maxHeight: .infinity)
    }

    private var secondary: some View {
        SecondaryAccount(document: $document,
                         account: account)
            .frame(minWidth: 400, idealWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Views

    var body: some View {
        VStack {
            if document.displaySettings.showSecondary {
                #if os(macOS)
                    HSplitView {
                        primary
                        secondary
                    }
                #else
                    HStack {
                        primary
                        secondary
                    }
                #endif
            } else {
                primary
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .principal) { viewControls }

            #if os(macOS)
                ToolbarItemGroup(placement: .primaryAction) { barControls }
            #else
                ToolbarItemGroup(placement: .automatic) {
                    NavigationLink(
                        destination: AccountRebalanceView(document: $document, account: account),
                        label: {
                            Text("Rebalance")
                        }
                    )
                    .disabled(!account.canTrade)

                    NavigationLink(
                        destination: HoldingTable(document: $document, account: account),
                        label: {
                            Text("Holdings")
                        }
                    )

                    NavigationLink(
                        destination: CapTable(document: $document, account: account),
                        label: {
                            Text("Caps")
                        }
                    )

                    NavigationLink(
                        destination: HistoryTable(document: $document, account: account),
                        label: {
                            Text("Transactions")
                        }
                    )
                }
            #endif
        }
    }

    @ViewBuilder
    private var viewControls: some View {
        ConsolidationToggles(document: $document)

        Spacer()

        SummarySelection.picker(summarySelection: $summarySelection)
            .pickerStyle(SegmentedPickerStyle())
    }

    @ViewBuilder
    private var barControls: some View {
        Spacer()

        InspectorToggle(on: $document.displaySettings.showSecondary)
    }
}
