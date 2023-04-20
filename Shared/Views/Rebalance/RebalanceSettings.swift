//
//  RebalanceSettings.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import FlowAllocHigh
import FlowBase

struct RebalanceSettings: View {
    @Binding var minimumSaleAmount: Int
    @Binding var minimumPositionValue: Int

    var body: some View {
        VStack(alignment: .leading) {
            Section(header: Text("Minimum Sale Amount")) {
                Picker(selection: $minimumSaleAmount, label: EmptyView()) {
                    Text("1").tag(1)
                    Text("5").tag(5)
                    Text("10").tag(10)
                    Text("25").tag(25)
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("500").tag(500)
                    Text("1000").tag(1000)
                    Text("5000").tag(5000)
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            Section(header: Text("Minimum Position Size")) {
                Picker(selection: $minimumPositionValue, label: EmptyView()) {
                    Text("1").tag(1)
                    Text("5").tag(5)
                    Text("10").tag(10)
                    Text("25").tag(25)
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("500").tag(500)
                    Text("1000").tag(1000)
                    Text("5000").tag(5000)
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            Spacer()

            Button(action: {
                minimumSaleAmount = ModelSettings.defaultMinimumSaleAmount
                minimumPositionValue = ModelSettings.defaultMinimumPositionValue
            }, label: {
                Text("Restore Defaults")
            })
        }
        .padding()
    }
}
