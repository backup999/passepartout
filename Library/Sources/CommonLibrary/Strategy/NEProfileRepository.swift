//
//  NEProfileRepository.swift
//  Passepartout
//
//  Created by Davide De Rosa on 10/10/24.
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

import Combine
import Foundation
import NetworkExtension
import PassepartoutKit

public final class NEProfileRepository: ProfileRepository {
    private let repository: NETunnelManagerRepository

    private let title: (Profile) -> String

    private let profilesSubject: CurrentValueSubject<[Profile], Never>

    private var subscriptions: Set<AnyCancellable>

    public init(repository: NETunnelManagerRepository, title: @escaping (Profile) -> String) {
        self.repository = repository
        self.title = title
        profilesSubject = CurrentValueSubject([])
        subscriptions = []

        repository
            .managersPublisher
            .sink { [weak self] in
                self?.onUpdatedManagers($0)
            }
            .store(in: &subscriptions)
    }

    public var profilesPublisher: AnyPublisher<[Profile], Never> {
        profilesSubject.eraseToAnyPublisher()
    }

    public func fetchProfiles() async throws -> [Profile] {
        let managers = try await repository.fetch()
        let profiles = managers.compactMap {
            do {
                return try repository.profile(from: $0)
            } catch {
                pp_log(.App.profiles, .error, "Unable to decode profile from NE manager '\($0.localizedDescription ?? "")': \(error)")
                return nil
            }
        }
        profilesSubject.send(profiles)
        return profiles
    }

    public func saveProfile(_ profile: Profile) async throws {
        try await repository.save(profile, forConnecting: false, options: nil, title: title)
    }

    public func removeProfiles(withIds profileIds: [Profile.ID]) async throws {
        guard !profileIds.isEmpty else {
            return
        }
        for id in profileIds {
            try await repository.remove(profileId: id)
        }
    }

    public func removeAllProfiles() async throws {
        try await removeProfiles(withIds: profilesSubject.value.map(\.id))
    }
}

private extension NEProfileRepository {
    func onUpdatedManagers(_ managers: [Profile.ID: NETunnelProviderManager]) {
        let profiles = managers.values.compactMap {
            do {
                return try repository.profile(from: $0)
            } catch {
                pp_log(.App.profiles, .error, "Unable to decode profile from NE manager '\($0.localizedDescription ?? "")': \(error)")
                return nil
            }
        }
        profilesSubject.send(profiles)
    }
}
