//
//  ConsolidationToggles.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import FlowUI

#if os(macOS)
let strategyRollupColor = Color(.controlTextColor)
#else
let strategyRollupColor = Color.primary
#endif

#if os(macOS)
let strategyGroupRelatedColor = Color(.controlTextColor)
#else
let strategyGroupRelatedColor = Color.primary
#endif

#if os(macOS)
let strategyReduceRebalanceColor = Color(.controlTextColor)
#else
let strategyReduceRebalanceColor = Color.primary
#endif

struct ConsolidationToggles: View {
    @Binding var document: AllocatDocument
    var body: some View {
        HStack(spacing: 2) {
            ColoredSystemImageToggle(on: $document.modelSettings.rollupAssets,
                                     color: strategyRollupColor,
                                     systemImageNameOn: "square.stack.3d.up.fill",
                                     systemImageNameOff: "square.stack.3d.up.slash",
                                     help: "Roll Up Assets")

            ColoredSystemImageToggle(on: $document.modelSettings.groupRelatedHoldings,
                                     color: strategyGroupRelatedColor,
                                     systemImageNameOn: "h.square.fill.on.square.fill",
                                     systemImageNameOff: "h.square.on.square",
                                     help: "Group Related Holdings")

            ColoredSystemImageToggle(on: $document.modelSettings.reduceRebalance,
                                     color: strategyReduceRebalanceColor,
                                     systemImageNameOn: "arrow.down.square.fill",
                                     systemImageNameOff: "arrow.down.square",
                                     help: "Reduce Rebalance")
        }
    }

    private var controlTextColor: Color {
        #if os(macOS)
        Color(.controlTextColor)
        #else
        Color.primary
        #endif
    }
}
