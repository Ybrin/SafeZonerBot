//
//  StartCommand.swift
//  App
//
//  Created by Koray Koska on 31.01.19.
//

import Vapor
import TelegramBot
import TelegramBotPromiseKit
import PromiseKit

class StartCommand: BaseCommand {

    static let command: String = "/start"

    let message: TelegramMessage

    let token: String

    required init(message: TelegramMessage, token: String) {
        self.message = message
        self.token = token
    }

    func run() throws {
        let chat = message.chat
        let chatId = chat.id
        let chatTitle = chat.title
        let chatFirstName = chat.firstName

        var chatName = "1 Larry"
        if let chatTitle = chatTitle {
            chatName = chatTitle
        } else if let chatFirstName = chatFirstName {
            chatName = chatFirstName
        }

        let text: String
        if chat.type == .privateChat || chat.type == .channelChat {
            text = "Hi \(chatName)! Welcome to SafeZoner. Please add me to your groups to start muting people."
        } else {
            text = "Hi \(chatName)! Welcome to SafeZoner. You can now start muting people with /mute."
        }

        let sendApi = TelegramSendApi(token: token, provider: SnakeTelegramProvider(token: token))

        sendApi.sendMessage(message: TelegramSendMessage(chatId: chatId, text: text))
    }
}
