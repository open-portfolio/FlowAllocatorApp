//
//  PrimaryAccount.swift
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
import FlowUI

enum TabsAccountTable: Int {
    case holdings
    case holdingsRaw
    case alloc
    case rebalanceSummary
    case rebalanceSales
    case rebalancePurchases
    case orphaned

    static let defaultTab = TabsAccountTable.holdings
    static let storageKey = "PrimaryAccountTab"
}

struct PrimaryAccount: View {
    @AppStorage(TabsAccountTable.storageKey) var tab: TabsAccountTable = .defaultTab

    // MARK: - Parameters

    @Binding var document: AllocatDocument
    var account: MAccount
    @Binding var summarySelection: SummarySelection

    @State private var subtitle = ""
    @State private var helpTopic = ""

    // MARK: - Locals

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(account.titleID) — \(subtitle)\(summarySelectionDesc)")
                    .font(.title)

                Spacer()

                HelpButton(appName: "allocator", topicName: helpTopic)
            }
            .padding(.horizontal)
            .padding(.top)

            TabView(selection: $tab) {
                HoldingsSummaryTable(model: document.model,
                                     ax: document.context,
                                     holdingsSummaryMap: holdingsSummaryMap,
                                     assetTickerSummaryMap: getTickerMap(isBase: false),
                                     summarySelection: $summarySelection)
                    .tabItem { Text("Holdings") }
                    .tag(TabsAccountTable.holdings)

                if isGroupRelatedHoldings {
                    HoldingsSummaryTable(model: document.model,
                                         ax: document.context,
                                         holdingsSummaryMap: rawHoldingsSummaryMap,
                                         assetTickerSummaryMap: getTickerMap(isBase: true),
                                         summarySelection: $summarySelection)
                        .tabItem { Text("Base Holdings") }
                        .tag(TabsAccountTable.holdingsRaw)
                }

                ParticipatingHoldingsTable(document: $document, account: account)
                    .tabItem { Text("Participating") }
                    .tag(TabsAccountTable.alloc)

                if account.canTrade {
                    RebalanceSummaryTable(document: $document, account: account)
                        .tabItem { Text("Rebalance Summary") }
                        .tag(TabsAccountTable.rebalanceSummary)
                    RebalanceSalesTable(document: $document, account: account,
                                        salesMap: salesMap)
                        .tabItem { Text("Rebalance Sales") }
                        .tag(TabsAccountTable.rebalanceSales)
                    RebalancePurchasesTable(document: $document, account: account,
                                            purchasesMap: purchasesMap,
                                            losingSalesMap: losingSalesMap)
                        .tabItem { Text("Rebalance Purchases") }
                        .tag(TabsAccountTable.rebalancePurchases)
                } else {
                    OrphanedTable(document: $document, account: account)
                        .tabItem { Text("Orphaned") }
                        .tag(TabsAccountTable.orphaned)
                }
            }
        }
        .padding(.horizontal, 10)
        .onAppear {
            tabChangedAction(newValue: tab)
        }
        .onChange(of: tab, perform: tabChangedAction)
    }

    // MARK: - Properties

    private var isGroupRelatedHoldings: Bool {
        ax.isGroupRelatedHoldings
    }

    private var ax: HighContext {
        document.context
    }

    private var accountKey: AccountKey {
        account.primaryKey
    }

    private var holdingsSummaryMap: AssetHoldingsSummaryMap {
        // if no valid strategy available in the context, just show raw holdings by asset class
        guard ax.strategyKey.isValid else {
            return ax.rawAccountAssetHoldingsSummaryMap[accountKey] ?? [:]
        }

        if account.canTrade {
            return ax.mergedVariableAccountHoldingsSummaryMap[accountKey] ?? [:]
        } else {
            return ax.mergedFixedAccountHoldingsSummaryMap[accountKey] ?? [:]
        }
    }

    private var rawHoldingsSummaryMap: AssetHoldingsSummaryMap {
        if account.canTrade {
            return ax.rawVariableAccountHoldingsSummaryMap[accountKey] ?? [:]
        } else {
            return ax.rawFixedAccountHoldingsSummaryMap[accountKey] ?? [:]
        }
    }

    private func getTickerMap(isBase: Bool) -> AssetTickerHoldingsSummaryMap {
        let map: AssetHoldingsMap? = {
            // if no valid strategy available in the context, just show ticker data by asset class
            guard ax.strategyKey.isValid else {
                return ax.rawAccountAssetHoldingsMap[accountKey]
            }

            if isBase {
                return ax.baseAccountAssetHoldingsMap[accountKey]
            } else {
                return ax.mergedAccountAssetHoldingsMap[accountKey]
            }
        }()

        guard let map_ = map else { return [:] }
        return HoldingsSummary.getAssetTickerSummaryMap(map_, ax.securityMap)
    }

    // NOTE this should be the 'net' rebalance map
    private var baseRebalanceMap: RebalanceMap {
        document.allocationResult.accountRebalanceMap[accountKey] ?? [:]
    }

    private var reducerMap: ReducerMap {
        document.allocationResult.accountReducerMap[accountKey] ?? [:]
    }

    private var netRebalanceMap: RebalanceMap {
        ax.isReduceRebalance
            ? applyReducerMap(baseRebalanceMap, reducerMap, preserveZero: false)
            : baseRebalanceMap
    }

    private var accountSalesMap: AccountSalesMap {
        document.allocationResult.getAccountSalesMap(ax)
    }

    private var salesMap: SaleMap {
        let map = document.allocationResult.getSaleMap(ax, accountKey: accountKey)
        return map
    }

    private var purchasesMap: PurchaseMap {
        document.allocationResult.getPurchaseMap(ax, accountKey: accountKey)
    }

    private var losingSalesMap: AssetSalesMap {
        HighResult.getLosingSalesMap(ax, accountSalesMap)
    }

    // MARK: - Tab support

    private var summarySelectionDesc: String {
        switch tab {
        case .holdings, .holdingsRaw:
            return " — \(summarySelection.description)"
        default:
            return ""
        }
    }

    private func tabChangedAction(newValue _: TabsAccountTable) {
        switch tab {
        case .holdings:
            subtitle = "Holdings"
            helpTopic = "holdingsSummary"
        case .holdingsRaw:
            subtitle = "Base Holdings"
            helpTopic = "holdingsSummary"
        case .alloc:
            subtitle = "Holdings Participation (in Current Allocation)"
            helpTopic = "holdingsParticipation"
        case .rebalanceSummary:
            subtitle = "Rebalance Summary"
            helpTopic = "rebalanceSummary"
        case .rebalanceSales:
            subtitle = "Rebalance Sales"
            helpTopic = "rebalanceSales"
        case .rebalancePurchases:
            subtitle = "Rebalance Purchases"
            helpTopic = "rebalancePurchases"
        case .orphaned:
            subtitle = "Orphaned Holdings"
            helpTopic = "orphanedHoldings"
        }
    }
}
