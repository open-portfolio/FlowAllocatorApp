//
//  GridCategory.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

struct GridCategory<Content: View>: View {
    let title: String
    let color: Color?
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading) {
            Text(title.uppercased())
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)
                .foregroundColor(color ?? Color.gray)
                .padding(.bottom, 4)

            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
