//
//  BaseRebalanceCell.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import AllocData

import FlowBase

struct BaseRebalanceCell<Content>: View where Content: View {
    @Binding private var document: AllocatDocument
    private let title: String
    private let amount: Double
    private let assetKey: AssetKey
    private let rowContent: () -> Content
    
    init(document: Binding<AllocatDocument>, title: String, amount: Double, assetKey: AssetKey, rowContent: @escaping () -> Content) {
        _document = document
        self.title = title
        self.amount = amount
        self.assetKey = assetKey
        self.rowContent = rowContent
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .top) {
                Text(title)
                    .font(.largeTitle)
                    .bold()

                Spacer()

                Text(amount.toCurrency(style: .whole))
                    .font(.title3)
            }
            
            rowContent()
            
            Spacer()

            HStack(alignment: .bottom) {
                Text(assetTitle)
                    .font(.title3)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity,
               //minHeight: 170, // workaround for Monterey cell height issue
               maxHeight: .infinity)
        .foregroundColor(document.assetColorMap[assetKey]?.0 ?? Color.primary)
        .background(document.getBackgroundFill(assetKey))
        .cornerRadius(20)
    }
    
    private var assetTitle: String {
        document.context.assetMap[assetKey]?.title ?? "Unknown Asset Class"
    }
}

