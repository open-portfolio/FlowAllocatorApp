//
//  AccountHeaderCell.swift
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

struct AccountHeaderCell: View {
    @Binding var document: AllocatDocument

    let item: BaseColumnHeader
    let accountIndex: Int
    let key: String
    let onMove: (Int, Int) -> Void
    @Binding var moneySelection: MoneySelection
    let bgFill: AnyView

    @State private var dragOver = false

    // along with key, used to avoid conflict with ALLOCATION drag and drop
    let keySeparator: Character = ":"

    var body: some View {

        VStack(alignment: .center, spacing: 2) {
            Text("\(item.account.title ?? item.account.accountID)")
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .font(.headline)
            if item.account.title != nil {
                Text("(\(item.account.accountID))")
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .padding(.bottom, 4)
            }
            Text(formattedValue)
                .font(.subheadline)
        }
        .foregroundColor(controlTextColor)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bgFill)

        .onDrag { NSItemProvider(object: keyIndexStr as NSString) }
        .onDrop(of: ["public.utf8-plain-text"], isTargeted: $dragOver, perform: dropAction)
        .border(dragOver ? Color.green : Color.clear)
    }

    private var controlTextColor: Color {
        #if os(macOS)
        Color(.controlTextColor)
        #else
        Color.primary
        #endif
    }
    
    // MARK: - Helpers

    private var formattedValue: String {
        switch moneySelection {
        case .percentOfAccount, .percentOfStrategy:
            return item.fractionOfStrategy.toPercent1()
        case .amountOfStrategy:
            return item.accountValue.toCurrency(style: .whole)
        case .presentValue:
            return holdingsSummary.presentValue.toCurrency(style: .whole)
        case .gainLossAmount:
            return holdingsSummary.gainLoss.toCurrency(style: .whole, leadingPlus: true)
        case .gainLossPercent:
            return holdingsSummary.gainLossPercent?.toPercent1(leadingPlus: true) ?? ""
        case .orphaned:
            let oa = orphanedAmount
            if oa > 0 {
                return "\(orphanedAmount.toCurrency(style: .whole))*"
            } else {
                return ""
            }
        }
    }

    private var ax: HighContext {
        document.context
    }

    private var orphanedAmount: Double {
        guard let assetAmountMap = ax.fixedOrphanedMap[item.account.primaryKey] else { return 0 }
        return AssetValue.sumOf(assetAmountMap)
    }

    private var holdingsSummary: HoldingsSummary {
        let holdingsMap = ax.baseAccountAssetHoldingsMap
        guard let holdings = holdingsMap[item.account.primaryKey]
        else { return HoldingsSummary() }
        return HoldingsSummary.getSummary(holdings, ax.securityMap)
    }

    // MARK: - Drag and drop helpers

    private func dropAction(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { print("no provider"); return false }

        guard provider.canLoadObject(ofClass: NSString.self) else { print("provider cannot load string"); return false }

        _ = provider.loadObject(ofClass: NSString.self) { data, _ in
            if let keyIdxStr = data as? String,
               let fromIdx = getKeyIndex(keyIdxStr)
            {
                DispatchQueue.main.async {
                    //print("from \(fromIdx) to \(item.account.accountID) \(accountIndex)")
                    let toIdx = accountIndex
                    guard fromIdx >= 0, toIdx >= 0, fromIdx != toIdx else { return }

                    onMove(fromIdx, toIdx)
                }
            }
        }
        return true
    }

    private var keyIndexStr: String {
        "\(key)\(keySeparator)\(accountIndex)"
    }

    private func getKeyIndex(_ nuKeyIndexStr: String) -> Int? {
        let parts: [String] = nuKeyIndexStr.split(separator: keySeparator).map { String($0) }
        guard parts[0] == key,
              parts.count == 2,
              let idx = Int(parts[1])
        else { return nil }

        return idx
    }
}
