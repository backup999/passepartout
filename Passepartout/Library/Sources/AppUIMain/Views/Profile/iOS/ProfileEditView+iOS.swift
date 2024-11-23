//
//  ProfileEditView+iOS.swift
//  Passepartout
//
//  Created by Davide De Rosa on 6/22/24.
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

#if os(iOS)

import CommonLibrary
import CommonUtils
import PassepartoutKit
import SwiftUI

struct ProfileEditView: View, Routable {

    @ObservedObject
    var profileEditor: ProfileEditor

    let moduleViewFactory: any ModuleViewFactory

    @Binding
    var path: NavigationPath

    @Binding
    var paywallReason: PaywallReason?

    var flow: ProfileCoordinator.Flow?

    @State
    private var errorModuleIds: Set<UUID> = []

    var body: some View {
        debugChanges()
        return List {
            NameSection(
                name: $profileEditor.profile.name,
                placeholder: Strings.Placeholders.Profile.name
            )
            modulesSection
            StorageSection(
                profileEditor: profileEditor,
                paywallReason: $paywallReason
            )
            UUIDSection(uuid: profileEditor.profile.id)
        }
        .toolbar(content: toolbarContent)
        .navigationTitle(Strings.Global.Nouns.profile)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(for: NavigationRoute.self, destination: pushDestination)
    }
}

// MARK: -

private extension ProfileEditView {

    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            ProfileSaveButton(
                title: Strings.Global.Actions.save,
                errorModuleIds: $errorModuleIds
            ) {
                try await flow?.onCommitEditing()
            }
        }
        ToolbarItem(placement: .cancellationAction) {
            Button(Strings.Global.Actions.cancel, role: .cancel) {
                flow?.onCancelEditing()
            }
        }
    }

    var modulesSection: some View {
        Group {
            ForEach(profileEditor.modules, id: \.id, content: moduleRow)
                .onMove(perform: moveModules)
                .onDelete(perform: removeModules)

            addModuleButton
        }
        .themeSection(
            header: Strings.Global.Nouns.modules,
            footer: Strings.Views.Profile.ModuleList.Section.footer
        )
    }

    func moduleRow(for module: any ModuleBuilder) -> some View {
        EditorModuleToggle(profileEditor: profileEditor, module: module) {
            Button {
                push(.moduleDetail(moduleId: module.id))
            } label: {
                HStack {
                    Text(module.description(inEditor: profileEditor))
                    if errorModuleIds.contains(module.id) {
                        ThemeImage(.warning)
                    } else if profileEditor.isActiveModule(withId: module.id) {
                        PurchaseRequiredButton(
                            for: module as? AppFeatureRequiring,
                            paywallReason: $paywallReason
                        )
                    }
                    Spacer()
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }

    var addModuleButton: some View {
        let moduleTypes = profileEditor.availableModuleTypes.sorted {
            $0.localizedDescription.lowercased() < $1.localizedDescription.lowercased()
        }
        return Menu {
            ForEach(moduleTypes) { selectedType in
                Button(selectedType.localizedDescription) {
                    flow?.onNewModule(selectedType)
                }
            }
        } label: {
            Text(Strings.Views.Profile.Rows.addModule)
        }
        .disabled(moduleTypes.isEmpty)
    }
}

private extension ProfileEditView {
    func moveModules(from offsets: IndexSet, to newOffset: Int) {
        profileEditor.moveModules(from: offsets, to: newOffset)
    }

    func removeModules(at offsets: IndexSet) {
        profileEditor.removeModules(at: offsets)
    }
}

// MARK: - Destinations

private extension ProfileEditView {
    enum NavigationRoute: Hashable {
        case moduleDetail(moduleId: UUID)
    }

    @ViewBuilder
    func pushDestination(for item: NavigationRoute) -> some View {
        switch item {
        case .moduleDetail(let moduleId):
            ModuleDetailView(
                profileEditor: profileEditor,
                moduleId: moduleId,
                moduleViewFactory: moduleViewFactory
            )
            .environment(\.navigationPath, $path)
        }
    }

    func push(_ item: NavigationRoute) {
        path.append(item)
    }
}

#Preview {
    NavigationStack {
        ProfileEditView(
            profileEditor: ProfileEditor(profile: .newMockProfile()),
            moduleViewFactory: DefaultModuleViewFactory(registry: Registry()),
            path: .constant(NavigationPath()),
            paywallReason: .constant(nil)
        )
    }
    .withMockEnvironment()
}

#endif
