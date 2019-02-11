//
//  MessageParser.swift
//  App
//
//  Created by Koray Koska on 11.02.19.
//

import TelegramBot
import TelegramBotPromiseKit
import PromiseKit
import Dispatch

/// May only be called if no command is able to parse the message.
class MessageParser: BaseCommand {

    static let command: String = ""

    static func isParsable(message: TelegramMessage, botName: String) -> Bool {
        return true
    }

    let message: TelegramMessage

    let token: String

    required init(message: TelegramMessage, token: String) {
        self.message = message
        self.token = token
    }

    func run() throws {
        guard let from = message.from else {
            return
        }

        let sendApi = TelegramSendApi(token: token, provider: SnakeTelegramProvider(token: token))

        if StateManager.isAboutToMute(chat: message.chat, userId: from.id, type: .mute) {
            if let mutee = message.entities?.first {
                var response: String? = nil

                // Get optional time
                var until: Int?
                var secsToMute: Int?
                let spl = (message.text ?? "").split(separator: " ")
                if let last = spl.last, let seconds = Int(String(last)) {
                    until = message.date + seconds
                    secsToMute = seconds
                }

                if let text = message.text, mutee.type == .mention {
                    let muteeUsername = getUsername(text: text, entity: mutee)
                    StateManager.addMutedMember(chat: message.chat, username: muteeUsername, until: until)

                    response = "Successfully muted the offender \(muteeUsername)!"
                } else if let u = mutee.user, mutee.type == .textMention {
                    StateManager.addMutedMember(chat: message.chat, userId: u.id, until: until)

                    response = "Successfully muted [the offender](tg://user?id=\(u.id))!"
                }

                if var r = response {
                    r += " \(secsToMute != nil ? "For " + String(secsToMute!) + " seconds." : "")"

                    sendApi.sendMessage(message: TelegramSendMessage(chatId: message.chat.id, text: r, parseMode: .markdown))
                }
            }

            // Remove about to mute
            StateManager.removeAboutToMute(chat: message.chat, userId: from.id, type: .mute)
        } else if StateManager.isAboutToMute(chat: message.chat, userId: from.id, type: .unmute) {
            if let mutee = message.entities?.first {
                var response: String? = nil

                if let text = message.text, mutee.type == .mention {
                    let muteeUsername = getUsername(text: text, entity: mutee)
                    StateManager.removeMutedMember(chat: message.chat, username: muteeUsername)

                    response = "Successfully unmuted the former offender \(muteeUsername)!"
                } else if let u = mutee.user, mutee.type == .textMention {
                    StateManager.removeMutedMember(chat: message.chat, userId: u.id)

                    response = "Successfully unmuted [the former offender](tg://user?id=\(u.id))!"
                }

                if let r = response {
                    sendApi.sendMessage(message: TelegramSendMessage(chatId: message.chat.id, text: r, parseMode: .markdown))
                }
            }

            // Remove about to unmute
            StateManager.removeAboutToMute(chat: message.chat, userId: from.id, type: .unmute)
        }

        if StateManager.isMuted(chat: message.chat, user: from, at: message.date) {
            let queue = DispatchQueue(label: "MessageParser")
            firstly {
                sendApi.deleteMessage(chatId: .int(id: self.message.chat.id), messageId: self.message.messageId)
            }.done(on: queue) { bool in
                // Gay
            }.catch(on: queue) { error in
                let text = "I need the *delete_messages* permission to successfully mute offensive people!"
                sendApi.sendMessage(message: TelegramSendMessage(chatId: self.message.chat.id, text: text, parseMode: .markdown))
            }
        } else {
            // Remove user from muted members
            StateManager.removeMutedMember(chat: message.chat, user: from)
        }
    }

    func getUsername(text: String, entity: TelegramMessageEntity) -> String {
        let startIndex = text.index(text.startIndex, offsetBy: entity.offset)
        let endIndex = text.index(startIndex, offsetBy: entity.length)
        let muteeUsername = String(text[startIndex..<endIndex])

        return muteeUsername
    }
}
