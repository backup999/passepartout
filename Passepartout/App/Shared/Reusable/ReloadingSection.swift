//
//  ReloadingSection.swift
//  Passepartout
//
//  Created by Davide De Rosa on 4/4/22.
//  Copyright (c) 2022 Davide De Rosa. All rights reserved.
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

struct ReloadingSection<Header: View, Footer: View, T: Equatable, Content: View>: View {
    @Environment(\.scenePhase) private var scenePhase
    
    let header: Header
    
    let footer: Footer
    
    let elements: [T]
    
    var equality: ([T], [T]) -> Bool = { $0 == $1 }
    
    var isReloading = false

    var reload: (() -> Void)?
    
    @ViewBuilder let content: ([T]) -> Content
    
    @State private var localElements: [T] = []
    
    var body: some View {
        Section(
            header: header,//progressHeader,
            footer: footer
        ) {
            content(localElements)
        }.onAppear {
            localElements = elements
            if localElements.isEmpty {
                reload?()
            }
        }.onChange(of: elements) { newElements in
            guard !equality(localElements, newElements) else {
                return
            }
            withAnimation {
                localElements = newElements
            }
        }.onChange(of: scenePhase) {
            if $0 == .active {
                reload?()
            }
        }
    }
    
//    private var progressHeader: some View {
//        HStack {
//            header
//            if isReloading {
//                ProgressView()
//                    .padding(.leading, 5)
//            }
//        }
//    }
}