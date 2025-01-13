//
//  OpenVPNSession+Data.swift
//  PassepartoutKit
//
//  Created by Davide De Rosa on 3/28/24.
//  Copyright (c) 2024 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of PassepartoutKit.
//
//  PassepartoutKit is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  PassepartoutKit is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with PassepartoutKit.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import PassepartoutKit

extension OpenVPNSession {
    func handleDataPackets(
        _ packets: [Data],
        to tunnel: TunnelInterface,
        dataChannel: DataChannel
    ) async throws {
        do {
            guard let decryptedPackets = try await dataChannel.decrypt(packets: packets) else {
                pp_log(.openvpn, .error, "Unable to decrypt packets, is SessionKey properly configured (dataPath, peerId)?")
                return
            }
            guard !decryptedPackets.isEmpty else {
                return
            }
            reportInboundDataCount(decryptedPackets.flatCount)
            try await tunnel.writePackets(decryptedPackets)
        } catch {
            if let nativeError = error.asNativeOpenVPNError {
                throw nativeError
            }
            throw OpenVPNSessionError.recoverable(error)
        }
    }

    func sendDataPackets(
        _ packets: [Data],
        to link: LinkInterface,
        dataChannel: DataChannel
    ) async throws {
        do {
            guard let encryptedPackets = try await dataChannel.encrypt(packets: packets) else {
                pp_log(.openvpn, .error, "Unable to encrypt packets, is SessionKey properly configured (dataPath, peerId)?")
                return
            }
            guard !encryptedPackets.isEmpty else {
                return
            }
            reportOutboundDataCount(encryptedPackets.flatCount)
            try await link.writePackets(encryptedPackets)
        } catch {
            if let nativeError = error.asNativeOpenVPNError {
                throw nativeError
            }
            pp_log(.openvpn, .error, "Data: Failed LINK write during send data: \(error)")
            throw PassepartoutError(.linkFailure)
        }
    }
}