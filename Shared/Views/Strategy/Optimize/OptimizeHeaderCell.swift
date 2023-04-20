//
//  OptimizeHeaderCell.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import FlowAllocHigh
import FlowAllocLow
import FlowBase

struct OptimizeHeaderCell: View {
    @Binding var document: AllocatDocument

    var item: ResultSort
    let sortIndex: Int
    let key: String
    let onMove: (Int, Int) -> Void
    let onDirection: (ResultSort.Attribute, ResultSort.Direction) -> Void

    @State private var dragOver = false

    @State private var selection: String? = "b"

    // along with key, used to avoid conflict with ALLOCATION drag and drop
    let keySeparator: Character = ":"

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.clear)
                .border(Color.gray.opacity(0.3))

            VStack {
                titleLabel
                    .lineLimit(1)
                    .font(.headline)
            }
            .padding(.vertical, 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrag { NSItemProvider(object: keyIndexStr as NSString) }
        .onDrop(of: ["public.utf8-plain-text"], isTargeted: $dragOver, perform: dropAction)
        .border(dragOver ? Color.green : Color.clear)
        .contextMenu {
            getDirectionButton(.ascending, "Ascending")
            getDirectionButton(.descending, "Descending")
        }
    }

    private var titleLabel: some View {
        let title = ResultSort.getTitle(item.attribute)
        let systemName = item.direction == .ascending ? "chevron.up" : "chevron.down"
        return
            HStack(spacing: 3) {
                Text(title)
                Image(systemName: systemName).opacity(0.4)
            }
    }

    private func getDirectionButton(_ direction: ResultSort.Direction, _ title: String) -> some View {
        Button(action: {
            onDirection(item.attribute, direction)
        }) {
            Text("\(item.direction == direction ? "✓" : "   ") \(title)")
        }
    }

    // MARK: - Helpers

    // MARK: - Drag and drop helpers

    private func dropAction(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { print("no provider"); return false }

        guard provider.canLoadObject(ofClass: NSString.self) else { print("provider cannot load string"); return false }

        _ = provider.loadObject(ofClass: NSString.self) { data, _ in
            if let keyIdxStr = data as? String,
               let fromIdx = getKeyIndex(keyIdxStr)
            {
                DispatchQueue.main.async {
                    let toIdx = sortIndex
                    guard fromIdx >= 0, toIdx >= 0, fromIdx != toIdx else { return }

                    onMove(fromIdx, toIdx)
                }
            }
        }
        return true
    }

    private var keyIndexStr: String {
        "\(key)\(keySeparator)\(sortIndex)"
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
