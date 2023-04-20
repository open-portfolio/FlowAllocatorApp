//
//  OptimizeState.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import os

import Algorithms
import SwiftPriorityQueue

import FlowAllocHigh
import FlowAllocLow
import FlowBase

@available(macOS 11.0, *)
let oplog = Logger(subsystem: "app.flowallocator", category: "OptimizeState")

// needed for StateObject, which preserves operation queue across document refreshes
extension OperationQueue: ObservableObject {}

// to survive toggling the right sidebar
final class OptimizeState: ObservableObject {
    let timerInterval = 0.5

    var userLimitExceededCount: Int
    @Published var opCount: Int // published so progress goes to 100%
    var permutationsCompleted: Int

    // from settings
    public var maxHeap: Int
    public var maxCores: Int
    public var priority: OptimizePriority
    public var optimizeSortA: [ResultSort]
    public var optimizeSortB: [ResultSort]
    public var optimizeSortC: [ResultSort]

    var aPQ: HighResultQueue!
    var bPQ: HighResultQueue!
    var cPQ: HighResultQueue!

    @Published var timer: MyTimer // published so onReceive.objectWillChange receives events

    @Published var elapsedTimeFast: Double // refreshed via onReceive.objectWillChange on timer

    var operationQueue: OperationQueue

    // start coarsely, and get progressively finer
    public static var defaultFlowModes: [Double] {
        // Values from BlackBox at 2^7+1
        [0.000, 1.000, 0.500, 0.250, 0.750, 0.125, 0.375, 0.625,
         0.875, 0.062, 0.188, 0.312, 0.438, 0.562, 0.688, 0.812,
         0.938, 0.031, 0.094, 0.156, 0.219, 0.281, 0.344, 0.406,
         0.469, 0.531, 0.594, 0.656, 0.719, 0.781, 0.844, 0.906,
         0.969, 0.016, 0.047, 0.078, 0.109, 0.141, 0.172, 0.203,
         0.234, 0.266, 0.297, 0.328, 0.359, 0.391, 0.422, 0.453,
         0.484, 0.516, 0.547, 0.578, 0.609, 0.641, 0.672, 0.703,
         0.734, 0.766, 0.797, 0.828, 0.859, 0.891, 0.922, 0.953,
         0.984, 0.008, 0.023, 0.039, 0.055, 0.070, 0.086, 0.102,
         0.117, 0.133, 0.148, 0.164, 0.180, 0.195, 0.211, 0.227,
         0.242, 0.258, 0.273, 0.289, 0.305, 0.320, 0.336, 0.352,
         0.367, 0.383, 0.398, 0.414, 0.430, 0.445, 0.461, 0.477,
         0.492, 0.508, 0.523, 0.539, 0.555, 0.570, 0.586, 0.602,
         0.617, 0.633, 0.648, 0.664, 0.680, 0.695, 0.711, 0.727,
         0.742, 0.758, 0.773, 0.789, 0.805, 0.820, 0.836, 0.852,
         0.867, 0.883, 0.898, 0.914, 0.930, 0.945, 0.961, 0.977,
         0.992]
    }

    public init() {
        // oplog.debug("\(#function) ENTER"); defer { oplog.debug("\(#function) EXIT") }

        elapsedTimeFast = 0
        userLimitExceededCount = 0
        opCount = 0
        permutationsCompleted = 0
        maxHeap = 0
        maxCores = 0
        priority = .adaptive
        optimizeSortA = []
        optimizeSortB = []
        optimizeSortC = []

        timer = MyTimer(interval: timerInterval)
        operationQueue = OperationQueue()
    }

    func clearAction() {
        // oplog.debug("\(#function) ENTER"); defer { oplog.debug("\(#function) EXIT") }
        stopTimer()

        elapsedTimeFast = 0
        userLimitExceededCount = 0
        opCount = 0
        permutationsCompleted = 0

        aPQ?.clear(newOrder: HighResult.getOrder(optimizeSortA))
        bPQ?.clear(newOrder: HighResult.getOrder(optimizeSortB))
        cPQ?.clear(newOrder: HighResult.getOrder(optimizeSortC))
    }

    func stopTimer() {
        timer.stop()
    }

    // called from onReceive.objectWillChange event in view
    func updateElapsedTimeFast() {
        guard timer.isValid else { return }
        elapsedTimeFast = timer.elapsedIntervalSinceStart
    }

    func cancelOperationsAction() {
        // oplog.debug("\(#function) ENTER"); defer { oplog.debug("\(#function) EXIT") }
        operationQueue.cancelAllOperations()
        stopTimer()
    }

    func startAction(ax: HighContext, flowModes: [Double]) {
        // oplog.debug("\(#function) ENTER"); defer { oplog.debug("\(#function) EXIT") }
        stopTimer()

        maxHeap = ax.settings.optimizeMaxHeap
        maxCores = ax.settings.optimizeMaxCores
        priority = OptimizePriority(rawValue: ax.settings.optimizePriority) ?? OptimizePriority.default_
        optimizeSortA = ax.settings.optimizeSortA
        optimizeSortB = ax.settings.optimizeSortB
        optimizeSortC = ax.settings.optimizeSortC

        aPQ = HighResultQueue(name: "A",
                              order: HighResult.getOrder(optimizeSortA),
                              maxHeap: maxHeap)
        bPQ = HighResultQueue(name: "B",
                              order: HighResult.getOrder(optimizeSortB),
                              maxHeap: maxHeap)
        cPQ = HighResultQueue(name: "C",
                              order: HighResult.getOrder(optimizeSortC),
                              maxHeap: maxHeap)

        clearAction()

        guard maxHeap > 0, maxCores > 0
        else {
            oplog.error("bad maxHeap or maxCores"); return
        }

        let accountKeys = ax.variableAccountKeysForStrategy
        let assetKeys = ax.allocatingAllocAssetKeys
        let fixedAccountKeys = ax.fixedAccountKeysForStrategy.sorted()

        // validate before starting timer
        guard accountKeys.count > 0, assetKeys.count > 0
        else {
            oplog.error("no account or asset keys"); return
        }

        timer.start()

        let accountKeyPerms: PermutationsSequence<[AccountKey]> = accountKeys.permutations()
        let assetKeyPerms: PermutationsSequence<[AssetKey]> = assetKeys.permutations()

        operationQueue.maxConcurrentOperationCount = maxCores

        operationQueue.qualityOfService = {
            switch priority {
            case .adaptive:
                return .default
            case .high:
                return .userInitiated
            case .medium:
                return .utility
            case .low:
                return .background
            }
        }()

        let operations: [MyOperation] = flowModes.reduce(into: []) { operationsArray, flowMode in
            for accountKeys in accountKeyPerms {
                let op = generateOp(ax: ax,
                                    flowMode: flowMode,
                                    accountKeys: accountKeys,
                                    assetKeyPerms: assetKeyPerms,
                                    fixedAccountKeys: fixedAccountKeys)
                operationsArray.append(op)
            }
        }

        operationQueue.addOperations(operations, waitUntilFinished: false)
        opCount = operationQueue.operationCount
    }

    private func generateOp(ax: HighContext,
                            flowMode: Double,
                            accountKeys: [AccountKey],
                            assetKeyPerms: PermutationsSequence<[AssetKey]>,
                            fixedAccountKeys: [AccountKey]) -> MyOperation
    {
        // TOO MANY oplog.debug("\(#function) ENTER"); defer { oplog.debug("\(#function) EXIT") }
        let op = MyOperation(surgeContext: ax,
                             flowMode: flowMode,
                             variableAccountKeys: accountKeys,
                             assetKeyPerms: assetKeyPerms,
                             maxHeap: maxHeap,
                             fixedAccountKeys: fixedAccountKeys,
                             optimizeSortA: optimizeSortA,
                             optimizeSortB: optimizeSortB,
                             optimizeSortC: optimizeSortC)

        op.completionBlock = {
            if op.isCancelled { return }
            DispatchQueue.main.async {
                self.collectResults(from: op)
            }
        }

        return op
    }

    private func collectResults(from op: MyOperation) {
        // collect all the counts
        opCount = operationQueue.operationCount
        permutationsCompleted += op.count
        userLimitExceededCount += op.userLimitExceededCount

        // consolidate top-N results into main queues
        for result in op.aPQ.pq {
            aPQ.push(result)
        }
        for result in op.bPQ.pq {
            bPQ.push(result)
        }
        for result in op.cPQ.pq {
            cPQ.push(result)
        }

        updateElapsedTimeFast()

        if opCount == 0 {
            timer.stop()
        }
    }
}
