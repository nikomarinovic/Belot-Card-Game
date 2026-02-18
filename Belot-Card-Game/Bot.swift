import Foundation
import SwiftUI

final class AIBot {
    let player: Player
    unowned let manager: GameManager
    
    init(player: Player, manager: GameManager) {
        self.player = player
        self.manager = manager
    }
    // MARK: bot bira aduta
    func chooseTrump() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000)

            guard manager.trump == nil else { return }
            let hand = manager.hands[player.id] ?? []
            let suitCounts = Dictionary(grouping: hand, by: { $0.suit }).mapValues { $0.count }
            let bestCount = suitCounts.values.max() ?? 0
            let basePassChance = 60
            let adjustedPassChance = max(20, min(80, basePassChance - bestCount * 5))
            let shouldPass = Int.random(in: 0..<100) < adjustedPassChance
            if shouldPass {
                debugPrint("[Bot][Trump] \(player.name) says NEXT (chance: \(adjustedPassChance)%)")
                manager.chooseTrump(player: player, suit: nil)
                return
            }
            let suits = ["tref", "herc", "pik", "karo"]
            let sortedByCount = suits.sorted { (s1, s2) in
                (suitCounts[s1] ?? 0) > (suitCounts[s2] ?? 0)
            }
            let topTwo = Array(sortedByCount.prefix(2))
            let pickPool = topTwo.isEmpty ? suits : topTwo
            let suit = pickPool.randomElement() ?? suits.randomElement()!
            debugPrint("[Bot][Trump] \(player.name) chooses \(suit)")
            manager.chooseTrump(player: player, suit: suit)
        }
    }
    // MARK: bot igra kartu
    func playCard() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard manager.currentPlayer.id == player.id else { return }
            guard let hand = manager.hands[player.id], !hand.isEmpty else { return }

            let playableCards = manager.playableCards(for: player)

            if let card = playableCards.randomElement() {
                debugPrint("[Bot][Play] \(player.name) will play \(card.rank) of \(card.suit)")
                manager.playCard(player: player, card: card)
            }
        }
    }
}
