//
//  CDProviderRepositoryV3.swift
//  Passepartout
//
//  Created by Davide De Rosa on 10/26/24.
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

import AppData
import Combine
import CommonUtils
import CoreData
import Foundation
import PassepartoutKit

extension AppData {
    public static func cdProviderRepositoryV3(context: NSManagedObjectContext) -> ProviderRepository {
        CDProviderRepositoryV3(context: context)
    }
}

private final class CDProviderRepositoryV3: NSObject, ProviderRepository {
    private nonisolated let context: NSManagedObjectContext

    private nonisolated let providersSubject: CurrentValueSubject<[Provider], Never>

    private nonisolated let lastUpdateSubject: CurrentValueSubject<[ProviderID: Date], Never>

    private nonisolated let providersController: NSFetchedResultsController<CDProviderV3>

    init(context: NSManagedObjectContext) {
        self.context = context
        providersSubject = CurrentValueSubject([])
        lastUpdateSubject = CurrentValueSubject([:])

        let request = CDProviderV3.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "providerId", ascending: true)
        ]
        providersController = .init(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        super.init()

        Task {
            try await context.perform { [weak self] in
                self?.providersController.delegate = self
                try self?.providersController.performFetch()
            }
        }
    }

    nonisolated var indexPublisher: AnyPublisher<[Provider], Never> {
        providersSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    nonisolated var lastUpdatePublisher: AnyPublisher<[ProviderID: Date], Never> {
        lastUpdateSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func store(_ index: [Provider]) async throws {
        try await context.perform { [weak self] in
            guard let self else {
                return
            }
            do {
                // fetch existing for last update and deletion
                let request = CDProviderV3.fetchRequest()
                let results = try request.execute()
                let lastUpdatesByProvider = results.reduce(into: [:]) {
                    $0[$1.providerId] = $1.lastUpdate
                }
                results.forEach(context.delete)

                // replace but retain last update
                let mapper = CoreDataMapper(context: context)
                try index.forEach {
                    let lastUpdate = lastUpdatesByProvider[$0.id.rawValue]
                    try mapper.cdProvider(from: $0, lastUpdate: lastUpdate)
                }

                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    func store(_ infrastructure: VPNInfrastructure, for providerId: ProviderID) async throws {
        try await context.perform { [weak self] in
            guard let self else {
                return
            }
            do {
                let predicate = providerId.predicate

                // signal update of related provider
                let providerRequest = CDProviderV3.fetchRequest()
                providerRequest.predicate = predicate
                let providers = try providerRequest.execute()
                if let provider = providers.first {
                    provider.lastUpdate = infrastructure.lastUpdate
                }

                // delete all provider entities
                let serverRequest = CDVPNServerV3.fetchRequest()
                serverRequest.predicate = predicate
                let servers = try serverRequest.execute()
                servers.forEach(context.delete)

                let presetRequest = CDVPNPresetV3.fetchRequest()
                presetRequest.predicate = predicate
                let presets = try presetRequest.execute()
                presets.forEach(context.delete)

                // create new entities
                let mapper = CoreDataMapper(context: context)
                try infrastructure.servers.forEach {
                    try mapper.cdServer(from: $0)
                }
                try infrastructure.presets.forEach {
                    try mapper.cdPreset(from: $0)
                }

                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    nonisolated func vpnServerRepository(for providerId: ProviderID) -> VPNProviderServerRepository {
        CDVPNProviderServerRepositoryV3(context: context, providerId: providerId)
    }
}

extension CDProviderRepositoryV3: NSFetchedResultsControllerDelegate {
    nonisolated func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        guard let entities = controller.fetchedObjects as? [CDProviderV3] else {
            return
        }
        let mapper = DomainMapper()
        providersSubject.send(entities.compactMap(mapper.provider(from:)))
        lastUpdateSubject.send(mapper.lastUpdate(from: entities))
    }
}
