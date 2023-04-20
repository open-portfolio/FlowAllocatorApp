//
//  AllocatSidebar.swift
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

struct AllocatSidebar<HS>: View where HS: View {
    @Binding var document: AllocatDocument
    let strategiedHoldingsSummary: HS
    var isEmpty: Bool

    var body: some View {
        if !isEmpty {
            BirdsEyeSection(document: $document,
                            strategiedHoldingsSummary: strategiedHoldingsSummary)
                .padding()
        } else {
            AppIcon()
                .scaleEffect(1.5)
                .padding()
        }

        Spacer()
    }

    // MARK: - Properties

    private var ax: HighContext {
        document.context
    }
}
