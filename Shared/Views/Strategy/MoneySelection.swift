//
//  MoneySelection.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//


import SwiftUI

import FlowAllocHigh

extension MoneySelection {
    var description: String {
        switch self {
        case .percentOfAccount:
            return "Account Targets"
        case .percentOfStrategy:
            return "Strategy Targets"
        case .amountOfStrategy:
            return "Target Amounts"
        case .presentValue:
            return "Present Value of Holdings"
        case .gainLossAmount:
            return "Gain/Loss of Holdings"
        case .gainLossPercent:
            return "Gain/Loss of Holdings"
        case .orphaned:
            return "Orphaned Holdings"
        }
    }

    var symbol: String {
        switch self {
        case .percentOfAccount:
            return "%"
        case .percentOfStrategy:
            return "%"
        case .amountOfStrategy:
            return "$"
        case .presentValue:
            return "$"
        case .gainLossAmount:
            return "$"
        case .gainLossPercent:
            return "%"
        case .orphaned:
            return "$"
        }
    }

    var fullDescription: String {
        "\(description) (\(symbol))"
    }

    var systemImage: (String, String) {
        switch self {
        case .percentOfAccount:
            return ("rectangle.split.3x1", "rectangle.split.3x1.fill")
        case .percentOfStrategy:
            return ("rectangle.split.3x3", "rectangle.split.3x3.fill")
        case .amountOfStrategy:
            return ("dollarsign.square", "dollarsign.square.fill")
        case .presentValue:
            return ("shippingbox", "shippingbox.fill")
        case .gainLossAmount:
            return ("dollarsign.circle", "dollarsign.circle.fill")
        case .gainLossPercent:
            return ("plusminus.circle", "plusminus.circle.fill")
        case .orphaned:
            return ("trash.circle", "trash.circle.fill")
        }
    }

    var keyboardShortcut: KeyEquivalent {
        switch self {
        case .percentOfAccount:
            return "1"
        case .percentOfStrategy:
            return "2"
        case .amountOfStrategy:
            return "3"
        case .presentValue:
            return "4"
        case .gainLossAmount:
            return "5"
        case .gainLossPercent:
            return "6"
        case .orphaned:
            return "7"
        }
    }

    private static func myLabel(bsm: Binding<MoneySelection>, en: MoneySelection) -> some View {
        Image(systemName: bsm.wrappedValue == en ? en.systemImage.1 : en.systemImage.0)
    }

    static func picker(moneySelection: Binding<MoneySelection>) -> some View {
        Picker(selection: moneySelection, label: EmptyView()) {
            myLabel(bsm: moneySelection, en: MoneySelection.percentOfAccount)
                .tag(MoneySelection.percentOfAccount)
            myLabel(bsm: moneySelection, en: MoneySelection.percentOfStrategy)
                .tag(MoneySelection.percentOfStrategy)
            myLabel(bsm: moneySelection, en: MoneySelection.amountOfStrategy)
                .tag(MoneySelection.amountOfStrategy)
            myLabel(bsm: moneySelection, en: MoneySelection.presentValue)
                .tag(MoneySelection.presentValue)
            myLabel(bsm: moneySelection, en: MoneySelection.gainLossAmount)
                .tag(MoneySelection.gainLossAmount)
            myLabel(bsm: moneySelection, en: MoneySelection.gainLossPercent)
                .tag(MoneySelection.gainLossPercent)
            myLabel(bsm: moneySelection, en: MoneySelection.orphaned)
                .tag(MoneySelection.orphaned)
        }
        .pickerStyle(SegmentedPickerStyle())
        .help(moneySelection.wrappedValue.fullDescription)
    }
}
