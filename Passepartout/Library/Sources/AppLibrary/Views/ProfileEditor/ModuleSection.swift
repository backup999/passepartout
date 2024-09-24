//
//  ModuleSection.swift
//  Passepartout
//
//  Created by Davide De Rosa on 8/18/24.
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
import UtilsLibrary

enum ModuleRow: Hashable {
    enum CopyOnTap: Int, Hashable, Comparable {
        case disabled

        case caption

        case value

        case all

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    case text(caption: String, value: String? = nil)

    case textList(caption: String, values: [String])

    case copiableText(caption: String? = nil, value: String)

    case longContent(caption: String, value: String)

    case longContentPreview(caption: String, value: String, preview: String?)

    case push(caption: String, route: HashableRoute)
}

struct HashableRoute: Hashable {
    let route: any Hashable

    init(_ route: any Hashable) {
        self.route = route
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.route.hashValue == rhs.route.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(route)
    }
}

extension Collection {
    var nilIfEmpty: [Element]? {
        !isEmpty ? Array(self) : nil
    }
}

extension View {
    func moduleSection(for rows: [ModuleRow]?, header: String) -> some View {
        rows.map { rows in
            Section {
                ForEach(rows, id: \.self, content: moduleRowView)
            } header: {
                Text(header)
            }
        }
    }
}

private extension View {

    @ViewBuilder
    func moduleRowView(for row: ModuleRow) -> some View {
        switch row {
        case .text(let caption, let value):
            Text(caption)
                .withTrailingText(value)

        case .textList(let caption, let values):
            if !values.isEmpty {
                NavigationLink(caption) {
                    Form {
                        ForEach(Array(values.enumerated()), id: \.offset) {
                            Text($0.element)
                        }
                    }
                    .navigationTitle(caption)
                    .themeForm()
                }
            } else {
                Text(caption)
                    .withTrailingText(Strings.Global.empty)
            }

        case .copiableText(let caption, let value):
            ThemeCopiableText(title: caption, value: value)

        case .longContent(let title, let content):
            LongContentLink(title, content: .constant(content)) {
                Text($0)
                    .foregroundColor(.secondary)
            }

        case .longContentPreview(let title, let content, let preview):
            LongContentLink(title, content: .constant(content), preview: preview) {
                Text(preview != nil ? $0 : "")
                    .foregroundColor(.secondary)
            }

        case .push(let caption, let route):
            NavigationLink(caption, value: route.route)
        }
    }
}