//
//  BirdsEyeSection.swift
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
import FlowBase
import FlowUI
import FlowViz

struct BirdsEyeSection<HS>: View where HS: View {
    @Binding var document: AllocatDocument
    let strategiedHoldingsSummary: HS

    var body: some View {
        ZStack {
            VizRingView(holdingAllocs)
                .shadow(radius: 2, x: 3, y: 3)

            NavigationLink(
                destination: strategiedHoldingsSummary,
                tag: SidebarMenuIDs.globalHoldings.rawValue,
                selection: $document.displaySettings.activeSidebarMenuKey,
                label: {
                    Text(totalValue.toCurrency(style: .compact, leadingPlus: false, ifZero: ""))
                        .font(.system(.largeTitle, design: .monospaced))
                }
            )
        }
        .aspectRatio(1.0, contentMode: .fill)
        .contentShape(Rectangle()) // to ensure taps work in empty space
        .onTapGesture {
            document.displaySettings.activeSidebarMenuKey = SidebarMenuIDs.globalHoldings.rawValue
        }
    }

    private var ax: HighContext {
        document.context
    }

    private var totalValue: Double {
        ax.rawHoldingsSummary.presentValue
    }

    private var holdingAllocs: [VizSlice] {
        let holdingsSummaryMap = ax.rawHoldingsSummaryMap
        let tv = totalValue

        guard tv > 0 else { return [] }

        return holdingsSummaryMap.sorted(by: { $0.key < $1.key }).reduce(into: []) { array, item in

            guard let asset = ax.assetMap[item.key]
            else { return }

            let color = getColor(asset.colorCode)

            let targetPct = item.value.presentValue / tv

            array.append(VizSlice(targetPct, color.1)) // item.key.assetNormID
        }
    }
}

// struct BirdsEyeSection_Previews: PreviewProvider {
//    static var previews: some View {
//        BirdsEyeSection()
//    }
// }
