//
//  ConsolidationView.swift
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

struct ConsolidationView: View {
    @Binding var document: AllocatDocument
    var strategy: MStrategy

    var body: some View {
        VStack {
            HStack {
                Text("Consolidate")
                    .font(.title)
                    .lineLimit(1)

                Spacer()
                HelpButton(appName: "allocator", topicName: "consolidate")
            }
            .padding(.vertical)

            StatsBoxView(title: "Roll Up Assets") {
                Toggle(isOn: $document.modelSettings.rollupAssets, label: {
                    HStack {
                        Text("Enable Roll Up Assets")
                    }
                })

                HStack {
                    Text("Threshold")
                    Picker(selection: $document.modelSettings.rollupThreshold, label: EmptyView()) {
                        ForEach(0 ..< 21) { n in
                            Text("\(n)%").tag(n)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                    .frame(maxWidth: 100)
                }
                .padding(.horizontal)
            }

            StatsBoxView(title: "Group Related Holdings") {
                Toggle(isOn: $document.modelSettings.groupRelatedHoldings, label: {
                    HStack {
                        Text("Enable Group Related Holdings")
                    }
                })
            }

            StatsBoxView(title: "Reduce Rebalance") {
                Toggle(isOn: $document.modelSettings.reduceRebalance, label: {
                    HStack {
                        Text("Enable Reduce Rebalance")
                    }
                })
            }

            Spacer()

            Button(action: {
                document.modelSettings.rollupAssets = ModelSettings.defaultRollupAssets
                document.modelSettings.rollupThreshold = ModelSettings.defaultRollupThreshold
                document.modelSettings.groupRelatedHoldings = ModelSettings.defaultGroupRelatedHoldings
                document.modelSettings.reduceRebalance = ModelSettings.defaultReduceRebalance
            }, label: {
                Text("Restore Defaults")
            })
        }
        .padding(.horizontal, 10)
    }
}
