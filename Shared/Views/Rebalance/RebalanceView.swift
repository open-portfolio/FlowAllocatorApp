//
//  RebalanceView.swift
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

struct RebalanceView: View {
    @AppStorage("RebalanceViewTab") var tab: String = ""

    static let rebalanceSetupTabID = "608A0374-279D-42F9-BD80-F26E9B68CFE2"

    // MARK: - Parameters

    @Binding var document: AllocatDocument
    var strategy: MStrategy

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Rebalance (of Trading Accounts)")
                    .font(.title)
                    .lineLimit(1)

                Spacer()
                HelpButton(appName: "allocator", topicName: "rebalance")
                exportButton
            }
            .padding()

            TabView(selection: $tab) {
                ForEach(accounts, id: \.self) { account in
                    accountView(account)
                        .tabItem { Text(account.title ?? "") }
                        .tag(account.primaryKey.accountNormID)
                        .padding(.horizontal)
                }

                RebalanceSettings(minimumSaleAmount: $document.modelSettings.minimumSaleAmount,
                                  minimumPositionValue: $document.modelSettings.minimumPositionValue)
                    .tabItem { Text("Setup") }
                    .tag(RebalanceView.rebalanceSetupTabID)
            }
            .id(accounts.count)
            .padding(.horizontal)
            .padding(.bottom)

            Spacer() // to force title to top if no allocation yet
        }
    }

    private func accountView(_ account: MAccount) -> some View {
        VStack {
            Text("\(account.titleID)\(account.isTaxable ? " (taxable)" : "")")
                .font(.title2)
                .padding()
            AccountRebalanceView(document: $document, account: account)
        }
    }

    private var exportButton: some View {
        Button(action: exportAction) {
            Text("Export")
        }
    }

    // MARK: - Helpers

    private var ax: HighContext {
        document.context
    }

    private var ds: DisplaySettings {
        document.displaySettings
    }

    private var ms: ModelSettings {
        document.modelSettings
    }

    private var accountSalesMap: AccountSalesMap {
        document.allocationResult.getAccountSalesMap(ax)
    }

    private var accountPurchasesMap: AccountPurchasesMap {
        document.allocationResult.getAccountPurchasesMap(ax)
    }

    // array of accounts, ordered same as in surgeParams
    private var accounts: [MAccount] {
        ds.params.accountKeys.compactMap { ax.strategiedAccountMap[$0] }
    }

    // MARK: - Actions

    private func exportAction() {
        let tradingAllocations = MRebalanceAllocation.getAllocations(ax.variableAccountKeysForStrategy,
                                                                     ax.accountAllocatingValueMap,
                                                                     document.allocationResult.accountAllocMap,
                                                                     ax.accountMap,
                                                                     ax.assetMap)
        let nonTradingAllocations = MRebalanceAllocation.getAllocations(ax.fixedAccountKeysForStrategy,
                                                                        ax.accountAllocatingValueMap,
                                                                        ax.fixedAccountAllocationMap,
                                                                        ax.accountMap,
                                                                        ax.assetMap)
        let mpurchases = MRebalancePurchase.getPurchases(accountPurchasesMap, ax.accountMap, ax.assetMap)
        let msales = MRebalanceSale.getSales(accountSalesMap)

        if let data = try? packageRebalance(params: ds.params,
                                            tradingAllocations: tradingAllocations,
                                            nonTradingAllocations: nonTradingAllocations,
                                            mpurchases: mpurchases,
                                            msales: msales)
        {
            #if os(macOS)
                NSSavePanel.saveData(data, name: "rebalance", ext: "zip", completion: { _ in })
            #endif
        }
    }
}
