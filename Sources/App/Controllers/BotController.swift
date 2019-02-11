//
//  BotController.swift
//  App
//
//  Created by Koray Koska on 24.01.19.
//

import Foundation
import TelegramBot

final class BotController {

    let botName: String

    let token: String

    init(botName: String, token: String) {
        self.botName = botName
        self.token = token
    }

    func getMessage(id: Int, message: TelegramMessage) {
        let commands: [BaseCommand.Type] = [StartCommand.self, MuteCommand.self]

        var correctCommands: [BaseCommand] = []
        for command in commands {
            if command.isParsable(message: message, botName: botName) {
                correctCommands.append(command.init(message: message, token: token))
            }
        }

        // Don't run commands for muted members
        var mutedCommand = false
        if let from = message.from, StateManager.isMuted(chat: message.chat, user: from, at: message.date) {
            mutedCommand = true
        } else {
            for command in correctCommands {
                try? command.run()
            }
        }

        if correctCommands.count == 0 || mutedCommand {
            // Fallback message parser
            try? MessageParser(message: message, token: token).run()
        }
    }

    func getCallback(id: Int, callback: TelegramCallbackQuery) {
        let callbackQueries: [BaseCallbackQuery.Type] = []

        var correctCallbackQueries: [BaseCallbackQuery] = []
        for query in callbackQueries {
            if query.isParsable(callbackQuery: callback) {
                correctCallbackQueries.append(query.init(callbackQuery: callback, token: token))
            }
        }

        for query in correctCallbackQueries {
            try? query.run()
        }
    }
}
