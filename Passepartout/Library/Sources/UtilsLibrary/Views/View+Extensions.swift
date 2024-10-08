//
//  View+Extensions.swift
//  Passepartout
//
//  Created by Davide De Rosa on 2/18/22.
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

import SwiftUI

extension View {
    public func debugChanges(condition: Bool = false) {
        if condition {
            Self._printChanges()
        }
    }

    @ViewBuilder
    public func `if`(_ condition: Bool) -> some View {
        if condition {
            self
        }
    }

    public func withTrailingText(_ text: String?, truncationMode: Text.TruncationMode = .tail) -> some View {
        LabeledContent {
            if let text {
                Spacer()
                let trailing = Text(text)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(truncationMode)
                trailing
            }
        } label: {
            self
        }
    }
}

extension ViewModifier {
    public func debugChanges(condition: Bool = false) {
        if condition {
            Self._printChanges()
        }
    }
}

public func copyToPasteboard(_ string: String) {
#if os(iOS)
    let pb = UIPasteboard.general
    pb.string = string
#elseif os(macOS)
    let pb = NSPasteboard.general
    pb.clearContents()
    pb.setString(string, forType: .string)
#else
    fatalError("Copy unavailable")
#endif
}
