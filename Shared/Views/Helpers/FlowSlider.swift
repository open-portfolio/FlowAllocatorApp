//
//  FlowSlider.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import FlowUI

public typealias OnSliderChanged = () -> Void

struct FlowSlider: View {
    @Binding private var allocFlowMode: Double
    private var onSliderChanged: OnSliderChanged?
    
    @ObservedObject private var proxy: DebouncedHolder<Double>

    init(allocFlowMode: Binding<Double>,
         debounceMilliSecs: Int = 1000,
         onSliderChanged: OnSliderChanged? = nil)
    {
        _allocFlowMode = allocFlowMode

        self.onSliderChanged = onSliderChanged

        proxy = DebouncedHolder<Double>(initialValue: allocFlowMode.wrappedValue, milliseconds: debounceMilliSecs)
    }

    // MARK: - Views

    var body: some View {
        HStack(alignment: .center) {
            Slider(value: self.$proxy.value,
                   minimumValueLabel: Text("Mirror"),
                   maximumValueLabel: Text("Flow")) {
                EmptyView()
            }
            .padding()

            Divider()

            Text(String(format: "%0.1f%%", proxy.value * 100))
                .font(.system(.title2, design: .monospaced))
                .frame(minWidth: 65)
        }
        .onReceive(proxy.didChange) {
            if allocFlowMode != proxy.value {
                allocFlowMode = proxy.value
                onSliderChanged?()
            }
        }
    }
}

struct FlowSlider_Previews: PreviewProvider {
    struct TestHolder: View {
        @State private var allocFlowMode: Double = 0.72

        var body: some View {
            Form {
                FlowSlider(allocFlowMode: $allocFlowMode)
            }
        }
    }

    static var previews: some View {
        return TestHolder()
            // .previewLayout(.sizeThatFits)
            .previewLayout(.fixed(width: 700, height: 800))
            .environment(\.colorScheme, .dark)
    }
}
