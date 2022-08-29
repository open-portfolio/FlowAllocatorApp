//
//  OptimizeSettings.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import FlowBase
import FlowAllocHigh

struct OptimizeSettings: View {
    @Binding var document: AllocatDocument

    @State var maxHeap: Int
    @State var maxCores: Int
    @State var optimizePriority: OptimizePriority

    var body: some View {
        VStack(alignment: .leading) {
            Section(header: Text("Top-N Count")) {
                Picker(selection: $maxHeap, label: EmptyView()) {
                    Text("5").tag(5)
                    Text("10").tag(10)
                    Text("25").tag(25)
                    Text("50").tag(50)
                }
                .onChange(of: maxHeap, perform: {
                    document.modelSettings.optimizeMaxHeap = $0
                })
                .pickerStyle(SegmentedPickerStyle())
            }

            Section(header: Text("Max Cores")) {
                Picker(selection: $maxCores, label: EmptyView()) {
                    Text("1").tag(1)
                    Text("2").tag(2)
                    Text("4").tag(4)
                    Text("8").tag(8)
                    Text("12").tag(12)
                    Text("16").tag(16)
                    Text("32").tag(32)
                }
                .onChange(of: maxCores, perform: {
                    document.modelSettings.optimizeMaxCores = $0
                })
                .pickerStyle(SegmentedPickerStyle())
            }

            Section(header: Text("Priority")) {
                Picker(selection: $optimizePriority, label: EmptyView()) {
                    Text("Adaptive").tag(OptimizePriority.adaptive)
                    Text("High").tag(OptimizePriority.high)
                    Text("Medium").tag(OptimizePriority.medium)
                    Text("Low").tag(OptimizePriority.low)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .onChange(of: optimizePriority, perform: {
                document.modelSettings.optimizePriority = $0.rawValue
            })

            Spacer()

            Button(action: {
                maxHeap = ModelSettings.defaultOptimizeMaxHeap
                maxCores = ModelSettings.defaultOptimizeMaxCores
                optimizePriority = OptimizePriority.default_
            }, label: {
                Text("Restore Defaults")
            })
        }
        .padding()
    }
}
