//
//  AllocatDocument+FocusedValue.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

extension AllocatDocument: FocusedValueKey {
    public typealias Value = Binding<Self>
}

extension FocusedValues {
    var document: AllocatDocument.Value? {
        get { self[AllocatDocument.self] }
        set { self[AllocatDocument.self] = newValue }
    }
}
