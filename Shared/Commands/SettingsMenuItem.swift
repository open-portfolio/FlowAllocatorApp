//
//  MenuSettingsBool.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

struct SettingsMenuItemBool: View {
    @FocusedBinding(\.document) private var document: AllocatDocument?

    var keyPath: WritableKeyPath<AllocatDocument, Bool>
    var desc: String
    var enabled: Bool = true

    var body: some View {
        Button(action: {
            document?[keyPath: keyPath].toggle()
        }, label: {
            Text("\((document?[keyPath: keyPath] ?? false) ? "✓" : "   ") \(desc)")
        })
        .disabled(!enabled)
    }
}

struct SettingsMenuItemKeyed<T: Equatable>: View {
    @FocusedBinding(\.document) private var document: AllocatDocument?

    var keyPath: WritableKeyPath<AllocatDocument, T>
    var keyToMatch: T
    var desc: String

    var body: some View {
        Button(action: {
            document?[keyPath: keyPath] = keyToMatch
        }, label: {
            Text("\((document?[keyPath: keyPath] == keyToMatch) ? "✓" : "   ") \(desc)")
        })
    }
}
