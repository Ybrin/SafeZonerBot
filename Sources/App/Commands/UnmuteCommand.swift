//
//  UnmuteCommand.swift
//  App
//
//  Created by Koray Koska on 11.02.19.
//

import Vapor
import TelegramBot
import TelegramBotPromiseKit
import PromiseKit
import Dispatch

class UnmuteCommand: BaseCommand {

    static let command: String = "/unmute"

    let message: TelegramMessage

    let token: String

    required init(message: TelegramMessage, token: String) {
        self.message = message
        self.token = token
    }

    func run() throws {
        let chatId = message.chat.id
        guard let from = message.from else {
            return
        }

        let sendApi = TelegramSendApi(token: token, provider: SnakeTelegramProvider(token: token))

        let queue = DispatchQueue(label: "UnmuteCommand")
        firstly {
            sendApi.getChatMember(chatId: .int(id: chatId), userId: from.id)
        }.then(on: queue) { chatMember -> PromiseKit.Promise<TelegramMessage> in
            let text: String
            if chatMember.status == .administrator || chatMember.status == .creator {
                text = "Please tag the former offender, now PC bro, in your next message!"

                // Save session
                StateManager.addAboutToMute(chat: self.message.chat, userId: from.id, type: .unmute)
            } else {
                text = "This command may only be used by administrators and creators of this group!"
            }

            return sendApi.sendMessage(message: TelegramSendMessage(chatId: chatId, text: text))
        }.done(on: queue) { message in

        }.catch(on: queue) { error in
            print("*** UnmuteCommand: ERROR IN PROMISE CHAIN ***")
            print(error)
        }
    }
}
