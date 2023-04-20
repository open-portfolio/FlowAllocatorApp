//
//  AccountRebalanceView.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import AllocData

import FlowAllocHigh
import FlowAllocLow
import FlowBase

struct AccountRebalanceView: View {
    @Binding var document: AllocatDocument

    var account: MAccount

    static let minCellWidth = 200
    private let columns = [GridItem(.flexible(minimum: CGFloat(minCellWidth)))]

    var body: some View {
        ScrollView(showsIndicators: true) {
            LazyVGrid(columns: columns) {
                ForEach(sales, id: \.self) { sale in
                    RebalanceLiquidateCell(document: $document, account: account,
                                           sale: sale)
                }

                ForEach(purchases, id: \.self) { purchase in
                    RebalanceAcquireCell(document: $document, account: account,
                                         purchase: purchase,
                                         losingTaxableSales: losingTaxableSales(assetKey: purchase.assetKey),
                                         netPurchaseAmount: getNetAmount(purchase.assetKey))
                }
            }
        }
        .padding(.horizontal, 5)
    }

    // MARK: - Properties

    private var ax: HighContext {
        document.context
    }

    private var accountKey: AccountKey {
        account.primaryKey
    }

    private var salesMap: SaleMap {
        document.allocationResult.getSaleMap(ax, accountKey: accountKey)
    }

    private var purchasesMap: PurchaseMap {
        document.allocationResult.getPurchaseMap(ax, accountKey: accountKey)
    }

    private var accountSalesMap: AccountSalesMap {
        document.allocationResult.getAccountSalesMap(ax)
    }

    private var losingSalesMap: AssetSalesMap {
        HighResult.getLosingSalesMap(ax, accountSalesMap)
    }

    private var baseRebalanceMap: RebalanceMap {
        document.allocationResult.accountRebalanceMap[accountKey] ?? [:]
    }

    private var reducerMap: ReducerMap {
        document.allocationResult.accountReducerMap[accountKey] ?? [:]
    }

    private var netRebalanceMap: RebalanceMap {
        ax.isReduceRebalance ? applyReducerMap(baseRebalanceMap, reducerMap, preserveZero: false) : baseRebalanceMap
    }

    private func getNetAmount(_ assetKey: AssetKey) -> Double {
        netRebalanceMap[assetKey] ?? 0
    }

    // will exclude those sales which have dropped-out through reduction
    private var sales: [Sale] {
        let assetKeys = netRebalanceMap.map(\.key).sorted()
        return assetKeys.compactMap { salesMap[$0] }
    }

    // will exclude those purchases which have dropped-out through reduction
    private var purchases: [Purchase] {
        let assetKeys = netRebalanceMap.map(\.key).sorted()
        return assetKeys.compactMap { purchasesMap[$0] }
    }

    // TODO: summarize by loss on each securityID (using liquidateHoldings)
    private func losingTaxableSales(assetKey: AssetKey) -> [String] {
        guard let losingSales = losingSalesMap[assetKey] else { return [] }
        return losingSales.reduce(into: []) {
            let tickers = $1.tickerKeys.map { $0.securityNormID.uppercased() }
            let str = "\(tickers.joined(separator: "/")) \($1.netGainLoss.toCurrency(style: .compact))"
            $0.append(str)
        }
    }
}
