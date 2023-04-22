//
//  AllocatApp.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Combine
import os
import SwiftUI

import AllocData

import FlowAllocHigh
import FlowAllocLow
import FlowBase
import FlowUI

let log = Logger(subsystem: "app.flowallocator", category: "App")

@main
struct AllocatApp: App {
    @Environment(\.openURL) var openURL

    @StateObject private var infoMessageStore = InfoMessageStore()

    var body: some Scene {
        // indicates how to create and load new document, as well as to how to load existing ones

        DocumentGroup(newDocument: AllocatDocument()) { file in

            ContentView(document: file.$document)
                .environmentObject(infoMessageStore)
        }
        .commands {
            SidebarCommands() // adds a toggle sidebar to View menu
            ToolbarCommands()

            CommandGroup(after: CommandGroupPlacement.importExport) {
                ImportCommand()
            }

            CommandMenu("Strategy") {
                StrategyCommand()
            }

            CommandMenu("Account") {
                AccountCommand()
            }

            CommandGroup(before: CommandGroupPlacement.toolbar) {
                ViewCommand()
            }

            CommandGroup(replacing: CommandGroupPlacement.help) {
                Button(action: {
                    openURL(URL(string: "https://open-portfolio.github.io/allocator/contents")!)
                }, label: {
                    Text("FlowAllocator Help")
                })
            }

            CommandGroup(after: CommandGroupPlacement.help) {
                HelpCommand()
            }
        }

        #if os(macOS)
            Settings {
                SharedSettingsView(termsURL: URL(string: "https://open-portfolio.github.io/terms")!,
                                   privacyURL: URL(string: "https://open-portfolio.github.io/privacy")!)
                {
                    GeneralView()
                }
                .environmentObject(infoMessageStore)
            }
        #endif
    }
}
