//
//  PrimaryStrategy.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//


import SwiftUI

import AllocData

import FlowAllocLow
import FlowBase
import FlowAllocHigh
import FlowUI

struct PrimaryStrategy: View {
    
    @Binding var document: AllocatDocument
    var strategy: MStrategy
    var canShowGrid: Bool

    var body: some View {
        VStack(alignment: .leading) {
            if canShowGrid {
                if let desc = invalidStrategyDesc {
                    Text(desc)
                        .font(.title)
                } else {
                    StrategyGrid(document: $document,
                                 strategy: strategy)
                        .padding(.top, 10) // needed on macOS
                    StrategyFooter(document: $document)
                        .padding(.horizontal, 5)
                        .padding(.bottom)
                }
            } else {
                WelcomeView() {
                    GettingStarted(document: $document)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Helpers

    private var ax: HighContext {
        document.context
    }
    
    private var invalidStrategyDesc: String? {
        do {
            try strategy.validateDeep(against: ax)
            try MSecurity.validateDeep(against: ax)
        
        } catch let error as FlowBaseError {
            return error.description
        } catch {
            return error.localizedDescription
        }
        return nil
    }
}

