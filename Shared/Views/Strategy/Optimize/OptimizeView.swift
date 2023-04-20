//
//  OptimizeView.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Algorithms
import Combine
import SwiftUI

import AllocData
import SwiftPriorityQueue

import FlowAllocHigh
import FlowAllocLow
import FlowBase
import FlowUI

enum TabsOptimize: Int {
    case setup
    case resultsA
    case resultsB
    case resultsC

    static let defaultTab = TabsOptimize.resultsA
    static let storageKey = "OptimizeTab"
}

struct OptimizeView: View {
    @AppStorage(TabsOptimize.storageKey) var tab: TabsOptimize = .defaultTab

    // MARK: - Parameters

    @Binding var document: AllocatDocument
    var strategy: MStrategy

    // NOTE this apparent redundancy is needed because change events are not propagating if referring to document.optimize, as in...
    // private var optimize: OptimizeState { document.optimize }
    @ObservedObject var optimize: OptimizeState

    // MARK: - Locals

    let permutationCountThreshold = 20_000_000

    @State private var resultMap = [TabsOptimize: HighResult]()
    @State private var userStopped = false

    // MARK: - Initialization

    var body: some View {
        ScrollView {
            HStack {
                Text("Strategy Optimize")
                    .font(.title)
                    .lineLimit(1)

                Spacer()
                HelpButton(appName: "allocator", topicName: "optimize")
            }
            .padding()

            HStack {
                StatsBoxView(title: "Progress") {
                    StatusDisplay(title: nil, value: progress, format: { "\($0.toPercent1())" }, textStyle: .title)
                }

                StatsBoxView(title: "Time") {
                    StatusDisplay(title: "Elapsed (secs)", value: optimize.elapsedTimeFast, format: { $0.toGeneral() })
                        .padding(.bottom, 5)
                    StatusDisplay(title: "Estimated Total", value: estimatedSecs > 0 ? max(60, estimatedSecs) : 0, format: formatEstimate)
                }
                StatsBoxView(title: "Performance") {
                    StatusDisplay(title: "Allocations/sec", value: permutationsPerSecond, format: { $0.toGeneral(style: .compact) })
                        .padding(.bottom, 5)
                    StatusDisplay(title: "Cap Discard Rate", value: capRate, format: { $0.toPercent1() })
                }
                StatsBoxView(title: "Allocations") {
                    StatusDisplay(title: "Completed", value: Double(permutationsCompleted), format: { $0.toGeneral(style: .compact) })
                        .padding(.bottom, 5)
                    StatusDisplay(title: "Total", value: Double(permutationCount), format: { $0.toGeneral(style: .compact) })
                        .foregroundColor(permutationCount > permutationCountThreshold ? Color.red : Color.primary)
                }
            }
            .frame(maxHeight: 140) // needed on macOS in full screen
            .padding(.horizontal)

            HStack {
                Button(action: startAction, label: {
                    Label("Optimize", systemImage: "play.fill")
                })
                .disabled(!ready)

                Button(action: stopAction, label: {
                    Label("Stop", systemImage: "stop.fill")
                })
                .disabled(ready)

                Spacer()

                Button(action: clearAction, label: {
                    Label("Clear Results", systemImage: "xmark")
                })
                .disabled(!ready)
            }
            .padding()

            TabView(selection: $tab) {
                OptimizeTable(document: $document, sorts: $document.modelSettings.optimizeSortA,
                              results: optimize.aPQ?.pq.reversed() ?? [],
                              assetValueMap: allocMap,
                              onSetResult: setResultAction,
                              onConfigChange: { clearAction() },
                              tab: .resultsA)
                    .tabItem { Text("Results A") }
                    .tag(TabsOptimize.resultsA)

                OptimizeTable(document: $document, sorts: $document.modelSettings.optimizeSortB,
                              results: optimize.bPQ?.pq.reversed() ?? [],
                              assetValueMap: allocMap,
                              onSetResult: setResultAction,
                              onConfigChange: { clearAction() },
                              tab: .resultsB)
                    .tabItem { Text("Results B") }
                    .tag(TabsOptimize.resultsB)

                OptimizeTable(document: $document, sorts: $document.modelSettings.optimizeSortC,
                              results: optimize.cPQ?.pq.reversed() ?? [],
                              assetValueMap: allocMap,
                              onSetResult: setResultAction,
                              onConfigChange: { clearAction() },
                              tab: .resultsC)
                    .tabItem { Text("Results C") }
                    .tag(TabsOptimize.resultsC)

                OptimizeSettings(document: $document,
                                 maxHeap: maxHeap,
                                 maxCores: maxCores,
                                 optimizePriority: optimizePriority)
                    .tabItem { Text("Setup") }
                    .tag(TabsOptimize.setup)
            }
            .frame(minHeight: 300, idealHeight: 600, maxHeight: .infinity)
            .onChange(of: tab, perform: tabChangedAction)
            .padding(.horizontal)

            Spacer()
        }
        .onReceive(optimize.timer.objectWillChange) { _ in
            optimize.updateElapsedTimeFast()
        }
    }

    // MARK: - Properties

    private var maxHeap: Int {
        document.modelSettings.optimizeMaxHeap
    }

    private var maxCores: Int {
        document.modelSettings.optimizeMaxCores
    }

    private var optimizePriority: OptimizePriority {
        let rawValue = document.modelSettings.optimizePriority
        return OptimizePriority(rawValue: rawValue) ?? OptimizePriority.default_
    }

    private var allocMap: AssetValueMap {
        let allocs = document.context.strategyAllocsMap[strategy.primaryKey] ?? []
        return AssetValue.getAssetValueMap(from: allocs)
    }

    private var ax: HighContext {
        document.context
    }

    private var userLimitExceededCount: Int {
        optimize.userLimitExceededCount
    }

    private var elapsedInterval: TimeInterval {
        optimize.timer.timerRefreshedElapsedInterval
    }

    private var permutationsCompleted: Int {
        optimize.permutationsCompleted
    }

    private var progress: Double {
        guard permutationCount > 0 else { return 0 }
        return Double(permutationsCompleted) / Double(permutationCount)
    }

    private var permutationsPerSecond: Double {
        guard elapsedInterval > 0 else { return 0 }
        return Double(permutationsCompleted) / elapsedInterval
    }

    private var capRate: Double {
        guard permutationsCompleted > 0 else { return 0 }
        return Double(userLimitExceededCount) / Double(permutationsCompleted)
    }

    private var permutationCount: Int {
        let accountCount = ax.variableAccountKeysForStrategy.count
        let assetCount = ax.allocatingAllocAssetKeys.count
        guard accountCount > 0,
              assetCount > 0
        else { return 0 }
        let count = OptimizeState.defaultFlowModes.count *
            factorial(accountCount) *
            factorial(assetCount)
        return count
    }

    private var estimatedSecs: Double {
        guard permutationsPerSecond > 0 else { return 0 }
        return Double(permutationCount) / permutationsPerSecond
    }

    private func formatEstimate(_ seconds: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.weekOfMonth, .day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: seconds) ?? ""
    }

    private var ready: Bool {
        userStopped || optimize.operationQueue.operationCount == 0
    }

    // MARK: - Action Handlers

    private func startAction() {
        userStopped = false
        optimize.startAction(ax: ax, flowModes: OptimizeState.defaultFlowModes)
    }

    private func stopAction() {
        userStopped = true
        optimize.cancelOperationsAction()
    }

    private func clearAction() {
        resultMap.removeAll()
        optimize.clearAction()
    }

    // MARK: - Helpers

    private func setParams(for result: HighResult) {
        let oldParams = document.displaySettings.params
        let newParams = result.getBaseParams(isStrict: oldParams.isStrict,
                                             fixedAccountKeys: oldParams.fixedAccountKeys)
        guard oldParams != newParams else { return }
        document.setParams(newParams)
    }

    private func setResultAction(for tab: TabsOptimize, _ result: HighResult) {
        resultMap[tab] = result
        setParams(for: result)
    }

    // MARK: - Tab support

    private func tabChangedAction(newValue: TabsOptimize) {
        if let result = resultMap[newValue] {
            setParams(for: result)
        }
    }
}
