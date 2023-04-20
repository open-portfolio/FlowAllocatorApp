//
//  StrategyFooter.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import FlowAllocHigh
import FlowAllocLow
import FlowBase
import FlowUI

struct StrategyFooter: View {
    @Binding var document: AllocatDocument

    var body: some View {
        VStack {
            upperControls
                .frame(height: 60)

            if document.displaySettings.strategyExpandBottom {
                FlowSlider(allocFlowMode: $document.displaySettings.params.flowMode,
                           debounceMilliSecs: 50,
                           onSliderChanged: sliderChangedAction)
                    .frame(height: 50)
                    .padding(.horizontal, 5)
            }
        }
    }

    private var upperControls: some View {
        HStack(alignment: .center, spacing: 10) {
            MyToggleButton(value: $document.displaySettings.strategyExpandBottom, imageName: "slider.horizontal.below.rectangle")
                .foregroundColor(controlTextColor)
                .font(.largeTitle)

            StatsBoxView(title: "Net Gain/Loss") {
                StatusDisplay(title: nil, value: document.allocationResult.netTaxGains, format: { "\($0.toCurrency(style: .compact))" })
            }
            StatsBoxView(title: "Absolute Gain") {
                StatusDisplay(title: nil, value: document.allocationResult.absTaxGains, format: { "\($0.toCurrency(style: .compact))" })
            }
            StatsBoxView(title: "Sale Volume") {
                StatusDisplay(title: nil, value: document.allocationResult.saleVolume, format: { "\($0.toCurrency(style: .compact))" })
            }
            StatsBoxView(title: "Txns") {
                StatusDisplay(title: nil, value: Double(document.allocationResult.transactionCount), format: { "\($0.toGeneral(style: .whole))" })
            }
            StatsBoxView(title: "Wash Sale") {
                StatusDisplay(title: nil, value: document.allocationResult.washAmount, format: { "\($0.toCurrency(style: .compact))" })
            }
            if !document.displaySettings.strategyExpandBottom {
                StatsBoxView(title: "Flow") {
                    StatusDisplay(title: nil, value: document.displaySettings.params.flowMode, format: { "\($0.toPercent1())" })
                }
            }
        }
    }

    private var controlTextColor: Color {
        #if os(macOS)
            Color(.controlTextColor)
        #else
            Color.primary
        #endif
    }

    private func sliderChangedAction() {
        // document.pushParamsToUndoStack(undoManager)
        document.refreshHighResult()
    }
}
