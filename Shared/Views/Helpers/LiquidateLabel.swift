//
//  LiquidateLabel.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import FlowAllocLow
import FlowBase
import FlowAllocHigh

struct LiquidateLabel: View {
    @Binding var document: AllocatDocument

    let liquidateHolding: LiquidateHolding
    var blankIfZero: Bool = false

    var body: some View {
        Text(liquidateDescription)
    }

    private var liquidateDescription: String {
        let epsilon = 0.001

        let fractionalValue = liquidateHolding.fractionalValue

        let isAll = liquidateHolding.fraction.isEqual(to: 1.0, accuracy: epsilon)

        let amountCompactStr = fractionalValue?.toCurrency(style: .compact) ?? ""

        let shareCountStr = liquidateHolding.fractionalShareCount.toShares()

        let sharesStr = isAll ? "ALL \(shareCountStr) shares" : "~\(shareCountStr) shares"

        return "\(amountCompactStr) \(securityID ?? "") (\(sharesStr))"
    }

    private var securityID: SecurityID? {
        liquidateHolding.getTicker(document.context.securityMap)
    }
}
