//
//  CurrencyCodePicker.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//


import SwiftUI

struct CurrencyCodePicker<Label>: View where Label: View {
    @Environment(\.locale) private var locale

    @Binding var currencyCodeSelected: String

    var label: () -> Label

    private var descriptions = [String: String]() // currencyCode (key): description (value)

    private var sortedIDs = [String]()

    init(currencyCodeSelected: Binding<String>,
         @ViewBuilder label: @escaping () -> Label)
    {
        _currencyCodeSelected = currencyCodeSelected
        self.label = label

        Locale.commonISOCurrencyCodes.forEach {
            descriptions[$0] = getDescription($0)
        }

        sortedIDs = descriptions.keys.sorted(by: { descriptions[$0]! < descriptions[$1]! })
    }

    // MARK: - Views

    var body: some View {
        Picker(selection: $currencyCodeSelected, label: label()) {
            ForEach(self.sortedIDs, id: \.self) { currencyCode in

                Text("\(self.descriptions[currencyCode]!) (\(currencyCode))").tag(currencyCode)
            }
        }
        .pickerStyle(DefaultPickerStyle())
    }

    private func getDescription(_ currencyCode: String) -> String {
        if let desc = locale.localizedString(forCurrencyCode: currencyCode) {
            if currencyCode != desc { return desc }

            switch currencyCode {
            case "AUD":
                return "Australian Dollar"
            case "BRL":
                return "Brazilian Real"
            case "CAD":
                return "Canadian Dollar"
            case "CNY":
                return "Renminbi (Chinese Yuan)"
            case "EUR":
                return "Euro"
            case "GBP":
                return "Pound Sterling"
            case "HKD":
                return "Hong Kong Dollar"
            case "ILS":
                return "Israeli New Shekel"
            case "INR":
                return "Indian Rupee"
            case "JPY":
                return "Japanese Yen"
            case "KRW":
                return "South Korean Won"
            case "MXN":
                return "Mexican Peso"
            case "NZD":
                return "New Zealand Dollar"
            case "TWD":
                return "New Taiwan Dollar"
            case "USD":
                return "United States Dollar"
            case "VND":
                return "Vietnamese Dong"
            case "XAF":
                return "CFA Franc BEAC"
            case "XCD":
                return "East Caribbean Dollar"
            case "XOF":
                return "CFA Franc BCEAO"
            case "XPF":
                return "CFP Franc (Franc Pacifique)"
            default:
                return currencyCode
            }

        } else {
            return currencyCode
        }
    }
}
