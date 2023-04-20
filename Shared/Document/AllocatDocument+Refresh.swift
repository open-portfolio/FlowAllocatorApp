//
//  AllocatDocument+Refresh.swift
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

// MARK: - Dependency-based refresh routines

extension AllocatDocument {
    // Called when UNDO of params
    // Called when user clicks on a HighResult from the Optimization results.
    // NO LONGER called when user reorders accounts in strategy grid
    mutating func setParams(_ params: BaseParams) {
        guard params != displaySettings.params else { return }
        displaySettings.params = params
        refreshHighResult()
    }

    // refresh the result, without refreshing context (if not needed)
    // if you want to force the refresh context, set document.surgeContext.isValid = false
    mutating func refreshHighResult() {
        log.info("\(#function) ENTER"); defer { log.info("\(#function) EXIT") }

        if !context.strategyKey.isValid {
            let strategyKey: StrategyKey = modelSettings.activeStrategyKey
            guard strategyKey.isValid
            else {
                log.error("refreshHighResult failure: active strategy missing")
                return
            }
            refreshContext(strategyKey: strategyKey)
            return
        }

        do {
            let result = try HighResult.allocateRebalanceSummarize(context, displaySettings.params)
            allocationResult = result

            allocationTable = HighStrategyTable.create(context: context,
                                                       params: displaySettings.params,
                                                       accountAllocMap: result.accountAllocMap)

        } catch let error as AllocLowError2 {
            print(error.description)
        } catch let error as FlowBaseError {
            print(error.description)
        } catch {
            print(error.localizedDescription)
        }
    }

    // refresh context, even if valid
    mutating func refreshContext(strategyKey: StrategyKey) {
        log.info("\(#function) ENTER strategyKey=\(strategyKey.strategyNormID)"); defer { log.info("\(#function) EXIT") }

        optimizeAbort()

        let timestamp = Date()
        let ax = HighContext(model,
                             modelSettings,
                             strategyKey: strategyKey,
                             timestamp: timestamp)

        // if fresh context, update the params to reflect the accounts, allocations, etc.
        displaySettings.params.update(nuAccountKeys: ax.variableAccountKeysForStrategy,
                                      nuAssetKeys: ax.allocatingAllocAssetKeys,
                                      nuFixedAccountKeys: ax.fixedAccountKeysForStrategy.sorted())

        context = ax

        refreshHighResult()

        // rebuild SwiftUI-dependent context (that we're storing in document object)
        let colorCodeMap = MAsset.getColorCodeMap(model.assets)
        assetColorMap = getAssetColorMap(colorCodeMap: colorCodeMap)
    }
}
