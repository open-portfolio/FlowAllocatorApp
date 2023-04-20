//
//  MyOperation.swift
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

private let myOp = Logger(subsystem: "app.flowallocator", category: "MyOperation")

public class MyOperation: Operation {
    let ax: HighContext
    let flowMode: Double
    let variableAccountKeys: [AccountKey]
    let assetKeyPerms: PermutationsSequence<[AssetKey]>
    let maxHeap: Int
    let fixedAccountKeys: [AccountKey]

    public var aPQ: HighResultQueue
    public var bPQ: HighResultQueue
    public var cPQ: HighResultQueue

    public var count = 0
    public var userLimitExceededCount = 0
    public var gainDupesFound = 0
    public var volumeDupesFound = 0
    public var transactionDupesFound = 0

    public init(surgeContext: HighContext,
                flowMode: Double,
                variableAccountKeys: [AccountKey],
                assetKeyPerms: PermutationsSequence<[AssetKey]>,
                maxHeap: Int,
                fixedAccountKeys: [AccountKey],
                optimizeSortA: [ResultSort],
                optimizeSortB: [ResultSort],
                optimizeSortC: [ResultSort])
    {
        ax = surgeContext
        self.flowMode = flowMode
        self.variableAccountKeys = variableAccountKeys
        self.assetKeyPerms = assetKeyPerms
        self.maxHeap = maxHeap
        self.fixedAccountKeys = fixedAccountKeys

        let flowModeInt = Int(flowMode * 10000)

        aPQ = HighResultQueue(name: "A\(flowModeInt)", order: HighResult.getOrder(optimizeSortA), maxHeap: maxHeap)
        bPQ = HighResultQueue(name: "B\(flowModeInt)", order: HighResult.getOrder(optimizeSortB), maxHeap: maxHeap)
        cPQ = HighResultQueue(name: "C\(flowModeInt)", order: HighResult.getOrder(optimizeSortC), maxHeap: maxHeap)
    }

    override public func main() {
        if isCancelled { return }

        for assetKeys in assetKeyPerms {
            if isCancelled { return }

            let ap = BaseParams(accountKeys: variableAccountKeys,
                                assetKeys: assetKeys,
                                flowMode: flowMode,
                                isStrict: true,
                                fixedAccountKeys: fixedAccountKeys)

            count += 1

            do {
                let result = try HighResult.allocateRebalanceSummarize(ax, ap)

                aPQ.push(result)
                bPQ.push(result)
                cPQ.push(result)

            } catch let error as AllocLowError1 {
                if error == AllocLowError1.userLimitExceededUnderStrict {
                    userLimitExceededCount += 1
                } else {
                    myOp.error("FlowError \(error.description)")
                }
            } catch let error as AllocLowError2 {
                myOp.error("AllocatError \(error.description)")
            } catch let error as FlowBaseError {
                myOp.error("FlowBaseError \(error.description)")
            } catch {
                myOp.error("allocator \(error.localizedDescription)")
            }
        }
    }
}
