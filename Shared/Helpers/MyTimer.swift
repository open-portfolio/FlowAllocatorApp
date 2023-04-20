//
//  MyTimer.swift
//
// Copyright 2021, 2022  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

final class MyTimer: ObservableObject {
    var interval: Double
    var startDate: Date?

    internal init(interval: Double = 1.0) {
        self.interval = interval
    }

    var timer: Timer!

    // triggers objectWillChange in .onReceive()
    @Published var timerRefreshedElapsedInterval: TimeInterval = 0

    public var isValid: Bool {
        timer?.isValid ?? false
    }

    // this will be the accurate value to check from the 'slow' non-timer event-driven updates
    var elapsedIntervalSinceStart: TimeInterval {
        startDate?.distance(to: Date()) ?? 0
    }

    func start() {
        timer?.invalidate()
        startDate = Date()
        timerRefreshedElapsedInterval = 0
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) {
            // Note that if your timer block/closure needs access to instance variables from your class you have to take special care with self.

            // "[weak self]" creates a "capture group" for timer
            [weak self] _ in

            // Add a guard statement to bail out of the timer code
            // if the object has been freed.
            guard let strongSelf = self else {
                return
            }

            // Put the code that be called by the timer here.
            strongSelf.timerRefreshedElapsedInterval = strongSelf.elapsedIntervalSinceStart
        }
        timer.tolerance = interval / 2
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
