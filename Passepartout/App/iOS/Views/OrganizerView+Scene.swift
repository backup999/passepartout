//
//  OrganizerView+Scene.swift
//  Passepartout
//
//  Created by Davide De Rosa on 4/2/22.
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
import PassepartoutCore

extension OrganizerView {
    struct SceneView: View {
        @Environment(\.scenePhase) private var scenePhase

        @ObservedObject private var appManager: AppManager
        
        @ObservedObject private var profileManager: ProfileManager
        
        @ObservedObject private var vpnManager: VPNManager
        
        @ObservedObject private var productManager: ProductManager
        
        @Binding private var alertType: AlertType?
        
        @Binding private var didHandleSubreddit: Bool
        
        init(alertType: Binding<AlertType?>, didHandleSubreddit: Binding<Bool>) {
            appManager = .shared
            profileManager = .shared
            vpnManager = .shared
            productManager = .shared
            _alertType = alertType
            _didHandleSubreddit = didHandleSubreddit
        }
        
        var body: some View {

            // dummy text, EmptyView() does not trigger on*() handlers
            Text("Scene")
                .hidden()
                .onAppear(perform: onAppear)
                .onChange(of: scenePhase, perform: onScenePhase)
        }
        
        private func onAppear() {
            if !didHandleSubreddit {
                alertType = .subscribeReddit
            }
        }

        private func onScenePhase(_ phase: ScenePhase) {
            switch phase {
            case .active:
                if productManager.hasRefunded() {
                    Task {
                        await vpnManager.uninstall()
                    }
                }

            case .background:
                persist()

            default:
                break
            }
        }
        
        private func persist() {
            appManager.activeProfileId = profileManager.activeProfileId
            profileManager.persist()
        }
    }
}