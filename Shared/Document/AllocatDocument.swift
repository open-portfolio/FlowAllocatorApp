//
//  AllocatDocument.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI
import UniformTypeIdentifiers

import AllocData

import FlowAllocLow
import FlowBase
import FlowAllocHigh
import FlowUI

extension HighContext: ObservableObject {}

struct AllocatDocument {
    var model: BaseModel
    var modelSettings: ModelSettings // requiring context reset
    var displaySettings: DisplaySettings // NOT requiring context reset
    
    @ObservedObject var context: HighContext
    @ObservedObject var optimize: OptimizeState
    
    var allocationResult: HighResult
    var allocationTable: HighStrategyTable
    var assetColorMap: AssetColorMap
    
    // schemas to package/unpackage
    static var schemas: [AllocSchema] = [
        .allocStrategy,
        .allocAllocation,
        .allocAsset,
        .allocHolding,
        .allocAccount,
        .allocSecurity,
        .allocTransaction,
        .allocCap,
        .allocTracker,
    ]
    
    init() {
        let _model = BaseModel.getDefaultModel()
        let _modelSettings = ModelSettings()
        let _context = HighContext(_model,
                                    _modelSettings,
                                    strategyKey: MStrategy.emptyKey)

        model = _model
        modelSettings = _modelSettings
        displaySettings = DisplaySettings()
        context = _context
        allocationResult = HighResult()
        allocationTable = HighStrategyTable.create()
        assetColorMap = AssetColorMap()
        optimize = OptimizeState()
    }
}

extension UTType {
    static let allocatDocument = UTType(exportedAs: "app.flowallocator.portfolio")
}

extension AllocatDocument: FileDocument {
    
    static var readableContentTypes: [UTType] { [.allocatDocument] }
    static var writableContentTypes: [UTType] { [.allocatDocument] }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let _model = BaseModel()
        let _modelSettings = ModelSettings()
        let _context = HighContext(_model,
                                    _modelSettings,
                                    strategyKey: MStrategy.emptyKey)

        model = _model
        modelSettings = _modelSettings
        displaySettings = DisplaySettings()
        context = _context
        allocationResult = HighResult()
        allocationTable = HighStrategyTable.create()
        assetColorMap = AssetColorMap()
        optimize = OptimizeState()
        
        try model.unpackage(data: data,
                            schemas: AllocatDocument.schemas,
                            modelSettings: &modelSettings,
                            displaySettings: &displaySettings)
    }
    
    func fileWrapper(configuration config: WriteConfiguration) throws -> FileWrapper {
        let data = try model.package(schemas: AllocatDocument.schemas,
                                     modelSettings: modelSettings,
                                     displaySettings: displaySettings)
        return .init(regularFileWithContents: data)
    }

}
