//
//  AppDelegate.swift
//  Passepartout
//
//  Created by Davide De Rosa on 9/18/24.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import AppAccessibility
import AppLibrary
import CommonLibrary
import CommonUtils
import SwiftUI

@MainActor
final class AppDelegate: NSObject {
    let context: AppContext = {
        if AppCommandLine.contains(.uiTesting) {
            pp_log_g(.app, .info, "UI tests: mock AppContext")
            return .forUITesting
        }
        return AppContext()
    }()

#if os(macOS)
    let settings = MacSettingsModel(
        kvManager: Dependencies.shared.kvManager,
        loginItemId: BundleConfiguration.mainString(for: .loginItemId)
    )
#endif

    func configure(with uiConfiguring: AppLibraryConfiguring?) {
        CommonLibrary.assertMissingImplementations(with: context.registry)
        context.appearanceManager.apply()
        uiConfiguring?.configure(with: context)
    }
}
