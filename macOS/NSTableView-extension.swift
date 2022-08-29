//
//  NSTableView-extension.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

// TRIAL to remove background on list in macos
// via https://stackoverflow.com/questions/60454752/swiftui-background-color-of-list-mac-os
extension NSTableView {
    override open func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        backgroundColor = NSColor.clear
        enclosingScrollView?.drawsBackground = false
    }
}
