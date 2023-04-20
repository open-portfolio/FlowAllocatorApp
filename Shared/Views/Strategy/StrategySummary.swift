//
//  StrategySummary.swift
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

struct StrategySummary: View {
    @Binding var document: AllocatDocument
    var strategy: MStrategy

    var body: some View {
        VStack {
            #if os(macOS)
                if document.displaySettings.showSecondary {
                    HSplitView {
                        primary
                        secondary
                    }
                } else {
                    primary
                }
            #else
                primary
            #endif
        }
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                shuffleButton // NOTE: on iOS causing double navigation for undetermined reason

                Spacer()

                viewControls
                    .disabled(!canShowGrid)
            }
            #if os(macOS)
                ToolbarItemGroup(placement: .primaryAction) {
                    barControls
                }
            #else
                ToolbarItemGroup(placement: .automatic) {
                    NavigationLink(
                        destination: AllocationTable(document: $document, strategy: strategy),
                        label: {
                            Text("Allocation")
                        }
                    )

                    NavigationLink(
                        destination: OptimizeView(document: $document,
                                                  strategy: strategy,
                                                  optimize: document.optimize,
                                                  activeTab: TabsOptimize.defaultTab),
                        label: {
                            Text("Optimize")
                        }
                    )

                    NavigationLink(
                        destination: RebalanceView(document: $document,
                                                   strategy: strategy,
                                                   activeTab: ""),
                        label: {
                            Text("Rebalance")
                        }
                    )

                    NavigationLink(
                        destination: ConsolidationView(document: $document, strategy: strategy),
                        label: {
                            Text("Consolidation")
                        }
                    )
                }
            #endif
        }
    }

    private var primary: some View {
        PrimaryStrategy(document: $document, strategy: strategy, canShowGrid: canShowGrid)
            .frame(minWidth: 600, idealWidth: 800, maxWidth: .infinity, maxHeight: .infinity)
    }

    private var secondary: some View {
        SecondaryStrategy(document: $document, strategy: strategy)
            .frame(minWidth: 400, idealWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var viewControls: some View {
        ConsolidationToggles(document: $document)

        Spacer()

        MoneySelection.picker(moneySelection: $document.displaySettings.strategyMoneySelection)
            .pickerStyle(SegmentedPickerStyle())

        Spacer()

        HStack(spacing: 2) {
            ColoredSystemImageToggle(on: $document.displaySettings.strategyShowVariable,
                                     color: controlTextColor,
                                     systemImageNameOn: "t.square.fill",
                                     systemImageNameOff: "t.square",
                                     help: "Trading Accounts")

            ColoredSystemImageToggle(on: $document.displaySettings.strategyShowFixed,
                                     color: controlTextColor,
                                     systemImageNameOn: "n.square.fill",
                                     systemImageNameOff: "n.square",
                                     help: "Non-Trading Accounts")
        }
    }

    @ViewBuilder
    private var barControls: some View {
        Spacer()

        InspectorToggle(on: $document.displaySettings.showSecondary)
    }

    private var shuffleButton: some View {
        Button(action: { document.shuffleAction() }) {
            Image(systemName: "tornado")
                .foregroundColor(controlTextColor)
                .shadow(radius: 1, x: 2, y: 2)
        }
        .help("Strategy Shuffle")
    }

    private var controlTextColor: Color {
        #if os(macOS)
            Color(.controlTextColor)
        #else
            Color.primary
        #endif
    }

    private var disabledControlTextColor: Color {
        #if os(macOS)
            Color(.disabledControlTextColor)
        #else
            Color.secondary
        #endif
    }

    // MARK: - Helpers

    private var canShowGrid: Bool {
        document.activeAccounts.count > 0 && document.context.netAllocAssetKeys.count > 0
    }
}
