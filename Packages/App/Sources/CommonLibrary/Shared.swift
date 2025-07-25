//
//  Shared.swift
//  Passepartout
//
//  Created by Davide De Rosa on 8/11/24.
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

import Foundation
import Partout

extension LoggerCategory {
    public static let app = LoggerCategory(rawValue: "app")

    public enum App {
        public static let iap = LoggerCategory(rawValue: "app.iap")

        public static let migration = LoggerCategory(rawValue: "app.migration")

        public static let profiles = LoggerCategory(rawValue: "app.profiles")

        public static let web = LoggerCategory(rawValue: "app.web")
    }
}

extension Constants {
    public static let shared = Bundle.module.unsafeDecode(Constants.self, filename: "Constants")
}
