//
//  StateManager.swift
//  App
//
//  Created by Koray Koska on 11.02.19.
//

import Foundation
import TelegramBot
import Dispatch

class StateManager {

    struct AboutToMuteSession {

        let userId: Int
        let type: MuteType

        enum MuteType: String {
            case mute
            case unmute
        }
    }

    struct MuteSession {

        let userId: Int?
        let username: String?

        let until: Int?
    }

    private static var mutedMembers: [TelegramChat: [MuteSession]] = [:]

    private static var aboutToMute: [TelegramChat: [AboutToMuteSession]] = [:]

    private static let queue = DispatchQueue(label: "StateManager")

    static func addAboutToMute(chat: TelegramChat, userId: Int, type: AboutToMuteSession.MuteType) {
        queue.sync {
            var ids = StateManager.aboutToMute[chat] ?? []

            if ids.firstIndex(where: { $0.userId == userId }) == nil {
                ids.append(AboutToMuteSession(userId: userId, type: type))

                StateManager.aboutToMute[chat] = ids
            }
        }
    }

    static func removeAboutToMute(chat: TelegramChat, userId: Int, type: AboutToMuteSession.MuteType) {
        queue.sync {
            var ids = StateManager.aboutToMute[chat] ?? []

            if let index = ids.firstIndex(where: { $0.userId == userId && $0.type == type }) {
                ids.remove(at: index)

                StateManager.aboutToMute[chat] = ids
            }
        }
    }

    static func addMutedMember(chat: TelegramChat, userId: Int, until: Int? = nil) {
        queue.sync {
            var ids = StateManager.mutedMembers[chat] ?? []

            if ids.firstIndex(where: { $0.userId == userId }) == nil {
                ids.append(MuteSession(userId: userId, username: nil, until: until))

                StateManager.mutedMembers[chat] = ids
            }
        }
    }

    static func addMutedMember(chat: TelegramChat, username: String, until: Int? = nil) {
        queue.sync {
            var ids = StateManager.mutedMembers[chat] ?? []

            if ids.firstIndex(where: { $0.username == username }) == nil {
                ids.append(MuteSession(userId: nil, username: username, until: until))

                StateManager.mutedMembers[chat] = ids
            }
        }
    }

    static func removeMutedMember(chat: TelegramChat, user: TelegramUser) {
        StateManager.removeMutedMember(chat: chat, userId: user.id)
        if let username = user.username {
            StateManager.removeMutedMember(chat: chat, username: username)
        }
    }

    static func removeMutedMember(chat: TelegramChat, userId: Int) {
        queue.sync {
            var ids = StateManager.mutedMembers[chat] ?? []

            if let index = ids.firstIndex(where: { $0.userId == userId }) {
                ids.remove(at: index)

                StateManager.mutedMembers[chat] = ids
            }
        }
    }

    static func removeMutedMember(chat: TelegramChat, username: String) {
        queue.sync {
            var ids = StateManager.mutedMembers[chat] ?? []

            if let index = ids.firstIndex(where: { $0.username == username }) {
                ids.remove(at: index)

                StateManager.mutedMembers[chat] = ids
            }
        }
    }

    static func isMuted(chat: TelegramChat, user: TelegramUser, at: Int? = nil) -> Bool {
        let idMuted = StateManager.isMuted(chat: chat, userId: user.id, at: at)
        var usernameMuted = false

        if let username = user.username {
            usernameMuted = StateManager.isMuted(chat: chat, username: username, at: at)
        }

        return idMuted || usernameMuted
    }

    static func isMuted(chat: TelegramChat, userId: Int, at: Int? = nil) -> Bool {
        var muted = false

        queue.sync {
            if let at = at {
                muted = (StateManager.mutedMembers[chat] ?? []).contains(where: { $0.userId == userId && $0.until ?? Int.max > at })
            } else {
                muted = (StateManager.mutedMembers[chat] ?? []).contains(where: { $0.userId == userId })
            }
        }

        return muted
    }

    static func isMuted(chat: TelegramChat, username: String, at: Int? = nil) -> Bool {
        var muted = false

        var username = username
        if !username.starts(with: "@") {
            username = "@\(username)"
        }

        queue.sync {
            if let at = at {
                muted = (StateManager.mutedMembers[chat] ?? []).contains(where: { $0.username == username && $0.until ?? Int.max > at })
            } else {
                muted = (StateManager.mutedMembers[chat] ?? []).contains(where: { $0.username == username })
            }
        }

        return muted
    }

    static func isAboutToMute(chat: TelegramChat, userId: Int, type: AboutToMuteSession.MuteType) -> Bool {
        var aboutToMute = false

        queue.sync {
            aboutToMute = (StateManager.aboutToMute[chat] ?? []).contains(where: { $0.userId == userId && $0.type == type })
        }

        return aboutToMute
    }
}

extension TelegramChat: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: TelegramChat, rhs: TelegramChat) -> Bool {
        return lhs.id == rhs.id
    }
}
