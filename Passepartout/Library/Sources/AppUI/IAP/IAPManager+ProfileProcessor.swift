//
//  IAPManager+ProfileProcessor.swift
//  Passepartout
//
//  Created by Davide De Rosa on 9/10/24.
//  Copyright (c) 2024 Davide De Rosa. All rights reserved.
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

import Foundation
import PassepartoutKit

extension IAPManager: ProfileProcessor {
    func processedProfile(_ profile: Profile) throws -> Profile {
        var builder = profile.builder()

        // suppress on-demand rules if not eligible
        if !isEligible(for: .onDemand) {
            pp_log(.app, .notice, "Suppress on-demand rules, not eligible")

            if let onDemandModuleIndex = builder.modules.firstIndex(where: { $0 is OnDemandModule }),
                let onDemandModule = builder.modules[onDemandModuleIndex] as? OnDemandModule {

                var onDemandBuilder = onDemandModule.builder()
                onDemandBuilder.policy = .any
                builder.modules[onDemandModuleIndex] = onDemandBuilder.tryBuild()
            }
        }

        return try builder.tryBuild()
    }
}
