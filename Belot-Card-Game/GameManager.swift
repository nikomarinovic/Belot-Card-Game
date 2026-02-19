import Foundation
import Combine


// MARK: karta
struct Card: Identifiable, Equatable {
    let id = UUID()
    let suit: String
    let rank: String
    var imageName: String { "\(rank)_\(suit)" }
}

// MARK: zvanje jednog igraca
struct PlayerMeld: Identifiable {
    let id = UUID()
    let playerIndex: Int
    let points: Int
    let description: String
    let cards: [Card]      // karte koje cine to zvanje
}

// MARK: GameManager
class GameManager: ObservableObject {
    
    private var isDarkMode: Bool {
        get { UserDefaults.standard.bool(forKey: "isDarkMode") }
        set { UserDefaults.standard.set(newValue, forKey: "isDarkMode") }
    }
    private var vibrationsOn: Bool {
        get { UserDefaults.standard.object(forKey: "vibrationsOn") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "vibrationsOn") }
    }
    private var language: String {
        get { UserDefaults.standard.string(forKey: "language") ?? "English" }
        set { UserDefaults.standard.set(newValue, forKey: "language") }
    }

    // MARK: igraci / spil karata
    @Published var players: [Player]
    @Published var deck: [Card] = []
    @Published var hands: [UUID: [Card]] = [:]

    struct PlayedCard: Identifiable {
        let id = UUID()
        let playerIndex: Int
        let card: Card
    }
    @Published var playedCards: [PlayedCard] = []

    // MARK: adut
    @Published var trump: String? = nil
    @Published var trumpChooser: Player? = nil
    @Published var trumpSelectionIndex: Int? = nil
    private var passesThisRound: Set<UUID> = []

    // MARK: Zvanja
    // sva pronađena zvanja grupirana po igracu
    @Published var playerMelds: [PlayerMeld] = []
    // Koji tim dobiva bodove (0 = nitko ne dobiva)
    @Published var winningMeldTeam: Int = 0
    // Ukupni bodovi po timu prije dodatka zvanja
    @Published var rawMeldTeam1: Int = 0
    @Published var rawMeldTeam2: Int = 0
    // Bodovi koji ce biti dodani (ne dodaju se odmah)
    @Published var pendingMeldTeam1: Int = 0
    @Published var pendingMeldTeam2: Int = 0
    // prikaz zvanja
    @Published var meldCheckingPhase: Bool = false  // "Provjeravam zvanja..." 2s
    @Published var meldShowPhase: Bool = false       // prikaz zvanja (ako ih ima)
    // Je li bela (posebno zvanje) vec zvana ove runde
    @Published var belaCalledThisRound: Bool = false

    // MARK: (baba + kralj zvanje)
    @Published var showBelaPrompt: Bool = false
    private var pendingBelaCard: Card? = nil
    private var pendingBelaPlayer: Player? = nil

    // MARK: runda / djelitelj / redosljed
    @Published var roundNumber: Int = 1
    @Published var dealerIndex: Int = 0
    @Published var currentPlayerIndex: Int = 0

    // MARK: bodovanje
    @Published var roundScoreTeam1: Int = 0
    @Published var roundScoreTeam2: Int = 0
    @Published var totalScoreTeam1: Int = 0
    @Published var totalScoreTeam2: Int = 0

    // MARK: gotova igra
    @Published var gameIsOver: Bool = false
    @Published var gameWinner: Int? = nil

    // MARK: neispravan potez poruka
    @Published var illegalCardMessage: String? = nil

    var maxScore: Int = 1001
    var onGameOver: ((Int) -> Void)? = nil
    private var roundEnding = false

    // MARK: botovi
    var bots: [AIBot] = []

    // MARK: vrijednosti karata
    private let cardValues: [String: Int] = [
        "7": 0, "8": 0, "9": 0,
        "decko": 2, "baba": 3, "kralj": 4,
        "10": 10, "as": 11
    ]
    private let trumpCardValues: [String: Int] = [
        "7": 0, "8": 0, "baba": 3, "kralj": 4,
        "10": 10, "as": 11, "9": 14, "decko": 20
    ]
    // Redosljed za nizove (NE ISTI KAO SNAGA U IGRI)
    let rankOrder: [String: Int] = [
        "7": 0, "8": 1, "9": 2, "10": 3,
        "decko": 4, "baba": 5, "kralj": 6, "as": 7
    ]

    // MARK: inicijaliziranje igre
    init(players: [Player], maxScore: Int = 1001) {
        self.players = players
        self.maxScore = maxScore
        setupBots()
        startNewRound(resetDealer: false)
    }
    
    func team(for playerIndex: Int) -> Int {
        (playerIndex % 2 == 0) ? 1 : 2
    }

    // MARK: botovi
    func setupBots() {
        bots = players.filter { $0.isBot }.map { AIBot(player: $0, manager: self) }
    }
    private func bot(for player: Player) -> AIBot? {
        bots.first { $0.player.id == player.id }
    }

    // MARK: nova runda
    func startNewRound(resetDealer: Bool) {
        if !resetDealer {
            dealerIndex = (roundNumber == 1) ? 0 : dealerIndex
        }
        setupDeck()
        dealCards()
        playedCards.removeAll()
        trump = nil
        trumpChooser = nil
        passesThisRound.removeAll()
        roundEnding = false
        illegalCardMessage = nil
        roundScoreTeam1 = 0
        roundScoreTeam2 = 0
        playerMelds = []
        winningMeldTeam = 0
        rawMeldTeam1 = 0
        rawMeldTeam2 = 0
        pendingMeldTeam1 = 0
        pendingMeldTeam2 = 0
        meldCheckingPhase = false
        meldShowPhase = false
        belaCalledThisRound = false
        showBelaPrompt = false
        pendingBelaCard = nil
        pendingBelaPlayer = nil

        currentPlayerIndex = nextIndex(after: dealerIndex)
        trumpSelectionIndex = currentPlayerIndex

        debugPrint("[Round] #\(roundNumber) Dealer=\(players[dealerIndex].name)")
        maybeAskCurrentSelectorBotForTrump()
    }

    func endRoundAndAdvanceDealer() {
        roundNumber += 1
        dealerIndex = nextIndex(after: dealerIndex)
        startNewRound(resetDealer: true)
    }

    // MARK: djeli karte i spil
    func setupDeck() {
        let suits = ["tref", "herc", "pik", "karo"]
        let ranks = ["7", "8", "9", "10", "decko", "baba", "kralj", "as"]
        deck = suits.flatMap { s in ranks.map { r in Card(suit: s, rank: r) } }
        deck.shuffle()
    }
    func dealCards() {
        hands.removeAll()
        for player in players {
            hands[player.id] = Array(deck.prefix(8))
            deck.removeFirst(8)
        }
    }

    // MARK: odabir aduta
    func chooseTrump(player: Player, suit: String?) {
        guard let selectorIndex = trumpSelectionIndex,
              players[selectorIndex].id == player.id else { return }

        if let suit = suit {
            trump = suit
            trumpChooser = player
            trumpSelectionIndex = nil
            debugPrint("[Trump] \(player.name) → \(suit)")
            startMeldCheckPhase()
        } else {
            passesThisRound.insert(player.id)
            if passesThisRound.count >= players.count - 1 {
                let dealer = players[dealerIndex]
                if !passesThisRound.contains(dealer.id) {
                    trumpSelectionIndex = dealerIndex
                    if dealer.isBot { bot(for: dealer)?.chooseTrump() }
                    return
                }
            }
            let nextIdx = nextIndex(after: selectorIndex)
            trumpSelectionIndex = nextIdx
            if players[nextIdx].isBot { bot(for: players[nextIdx])?.chooseTrump() }
        }
    }
    private func maybeAskCurrentSelectorBotForTrump() {
        guard let idx = trumpSelectionIndex else { return }
        let p = players[idx]
        if p.isBot { bot(for: p)?.chooseTrump() }
    }

    // MARK: zvanja: "provjeravam zvanja..." 2s
    private func startMeldCheckPhase() {
        meldCheckingPhase = true
        meldShowPhase = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self else { return }
            self.meldCheckingPhase = false
            self.evaluateMelds()
            self.meldShowPhase = true

            // Prikazi zvanja 3s pa kreni s igrom
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.meldShowPhase = false
                self?.startTrickPlay()
            }
        }
    }

    // MARK: provjeri zvanja

    private func evaluateMelds() {
        playerMelds = []

        struct RawMeld {
            let playerIndex: Int
            let points: Int
            let description: String
            let cards: [Card]
            let isTrump: Bool
        }

        var allMelds: [RawMeld] = []

        for (idx, player) in players.enumerated() {
            guard let hand = hands[player.id] else { continue }
            let found = findMelds(in: hand)
            for m in found {
                let inTrump = m.cards.allSatisfy { $0.suit == trump }
                allMelds.append(RawMeld(
                    playerIndex: idx,
                    points: m.points,
                    description: m.description,
                    cards: m.cards,
                    isTrump: inTrump
                ))
                playerMelds.append(PlayerMeld(
                    playerIndex: idx,
                    points: m.points,
                    description: m.description,
                    cards: m.cards
                ))
            }
        }

        guard !allMelds.isEmpty else {
            rawMeldTeam1 = 0; rawMeldTeam2 = 0
            winningMeldTeam = 0
            pendingMeldTeam1 = 0; pendingMeldTeam2 = 0
            return
        }

        let turnOrder: [Int] = (0..<players.count).map {
            (nextIndex(after: dealerIndex) + $0) % players.count
        }

        func strength(_ m: RawMeld) -> (Int, Int, Int) {
            let trumpBonus = m.isTrump ? 1 : 0
            let turnPos    = turnOrder.firstIndex(of: m.playerIndex) ?? 999
            return (m.points, trumpBonus, -turnPos)
        }

        let team1Melds = allMelds.filter { team(for: $0.playerIndex) == 1 }
        let team2Melds = allMelds.filter { team(for: $0.playerIndex) == 2 }

        let bestT1 = team1Melds.max {
            let a = strength($0), b = strength($1)
            if a.0 != b.0 { return a.0 < b.0 }
            if a.1 != b.1 { return a.1 < b.1 }
            return a.2 < b.2
        }
        let bestT2 = team2Melds.max {
            let a = strength($0), b = strength($1)
            if a.0 != b.0 { return a.0 < b.0 }
            if a.1 != b.1 { return a.1 < b.1 }
            return a.2 < b.2
        }

        let t1raw = team1Melds.reduce(0) { $0 + $1.points }
        let t2raw = team2Melds.reduce(0) { $0 + $1.points }
        rawMeldTeam1 = t1raw
        rawMeldTeam2 = t2raw

        let winner: Int
        switch (bestT1, bestT2) {
        case (nil, nil):
            winner = 0
        case (_, nil):
            winner = 1
        case (nil, _):
            winner = 2
        case let (b1?, b2?):
            let s1 = strength(b1), s2 = strength(b2)
            if s1.0 != s2.0 {
                winner = s1.0 > s2.0 ? 1 : 2
            } else if s1.1 != s2.1 {
                winner = s1.1 > s2.1 ? 1 : 2
            } else {
                winner = s1.2 > s2.2 ? 1 : 2
            }
        }

        winningMeldTeam = winner

        let allSequenceMeldPoints = t1raw + t2raw
        if winner == 1 {
            pendingMeldTeam1 = allSequenceMeldPoints
            pendingMeldTeam2 = 0
            playerMelds = playerMelds.filter { team(for: $0.playerIndex) == 1 }
        } else if winner == 2 {
            pendingMeldTeam1 = 0
            pendingMeldTeam2 = allSequenceMeldPoints
            playerMelds = playerMelds.filter { team(for: $0.playerIndex) == 2 }
        } else {
            pendingMeldTeam1 = 0
            pendingMeldTeam2 = 0
        }

        debugPrint("[Melds] BestT1=\(bestT1?.points ?? 0) BestT2=\(bestT2?.points ?? 0) → winner=\(winner) | pending T1=\(pendingMeldTeam1) T2=\(pendingMeldTeam2)")
    }

    // MARK: pronalazak zvanja

    func findMelds(in hand: [Card]) -> [(points: Int, description: String, cards: [Card])] {
        var results: [(Int, String, [Card])] = []
        let rankGroups  = Dictionary(grouping: hand, by: { $0.rank })
        let suitGroups  = Dictionary(grouping: hand, by: { $0.suit })

        // 4 decka 200
        if let g = rankGroups["decko"], g.count == 4 {
            results.append((200, "4 Decka", g))
        }
        // 4 devetke 150
        if let g = rankGroups["9"], g.count == 4 {
            results.append((150, "4 Devetke", g))
        }
        // 4 asa, 4 desetke, 4 kralja, 4 babe 100
        for rank in ["as", "10", "kralj", "baba"] {
            if let g = rankGroups[rank], g.count == 4 {
                results.append((100, "4 \(rank.capitalized)", g))
            }
        }

        // Nizovi iste boje 3 ili vise
        for (suit, cards) in suitGroups {
            let sorted = cards.sorted { (rankOrder[$0.rank] ?? 0) < (rankOrder[$1.rank] ?? 0) }
            let seqs = findSequences(in: sorted)
            for seq in seqs {
                let pts: Int
                switch seq.count {
                case 3: pts = 20
                case 4: pts = 50
                default: pts = 100
                }
                results.append((pts, "Sequence of \(seq.count) (\(suit.capitalized))".localized, seq))
            }
        }

        return results
    }

    private func findSequences(in sorted: [Card]) -> [[Card]] {
        guard sorted.count >= 3 else { return [] }
        var result: [[Card]] = []
        var current: [Card] = [sorted[0]]

        for i in 1..<sorted.count {
            let prevRank = rankOrder[sorted[i-1].rank] ?? 0
            let curRank  = rankOrder[sorted[i].rank]  ?? 0
            if curRank == prevRank + 1 {
                current.append(sorted[i])
            } else {
                if current.count >= 3 { result.append(current) }
                current = [sorted[i]]
            }
        }
        if current.count >= 3 { result.append(current) }
        return result
    }

    // MARK: baba + kralj adut
    func playerHasBela(player: Player) -> Bool {
        guard let trump, let hand = hands[player.id] else { return false }
        let hasBaba  = hand.contains { $0.suit == trump && $0.rank == "baba" }
        let hasKralj = hand.contains { $0.suit == trump && $0.rank == "kralj" }
        return hasBaba && hasKralj
    }

    // FIX 1c: checkBelaOnPlay is called from playCard() AFTER the card is removed from hand.
    // We check whether the player still holds the partner card. This guarantees bela
    // is only called when both baba and kralj are/were in the hand, and belaCalledThisRound
    // ensures it is counted at most once per round.
    func checkBelaOnPlay(player: Player, card: Card) {
        guard !belaCalledThisRound else { return }
        guard let trump else { return }
        guard card.suit == trump, card.rank == "baba" || card.rank == "kralj" else { return }
        // After removal from hand, the partner card must still be there
        guard let hand = hands[player.id] else { return }
        let partnerRank = (card.rank == "baba") ? "kralj" : "baba"
        guard hand.contains(where: { $0.suit == trump && $0.rank == partnerRank }) else { return }

        if player.isBot {
            callBela(player: player)
        } else {
            pendingBelaCard   = card
            pendingBelaPlayer = player
            showBelaPrompt = true
        }
    }

    func callBela(player: Player) {
        guard !belaCalledThisRound else { return }
        belaCalledThisRound = true
        showBelaPrompt = false
        let playerIdx = players.firstIndex(where: { $0.id == player.id }) ?? 0
        let t = team(for: playerIdx)
        // FIX 1d: Add bela +20 only to the calling player's team's pending meld.
        // This is separate from sequence/group melds and is always valid regardless
        // of which team won the meld comparison.
        if t == 1 { pendingMeldTeam1 += 20 } else { pendingMeldTeam2 += 20 }
        debugPrint("[Bela] \(player.name) zvao belu +20 → Team \(t)")
    }

    func declineBela() {
        showBelaPrompt = false
        pendingBelaCard = nil
        pendingBelaPlayer = nil
    }

    // MARK: pocni igru
    private func startTrickPlay() {
        currentPlayerIndex = nextIndex(after: dealerIndex)
        maybeAskCurrentPlayerBotToPlay()
    }

    // MARK: igraj kartu
    func playCard(player: Player, card: Card) {
        guard players[currentPlayerIndex].id == player.id else { return }
        guard let hand = hands[player.id],
              let indexInHand = hand.firstIndex(of: card) else { return }

        let legal = playableCards(for: player)
        guard legal.contains(card) else {
            let msg = illegalReason(card: card, hand: hand)
            DispatchQueue.main.async { self.illegalCardMessage = msg }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.illegalCardMessage = nil }
            return
        }

        illegalCardMessage = nil
        // FIX 2: Remove the card from hand BEFORE checkBelaOnPlay so that
        // the partner-card check correctly reflects the remaining hand.
        hands[player.id]?.remove(at: indexInHand)
        playedCards.append(PlayedCard(playerIndex: currentPlayerIndex, card: card))
        debugPrint("[Play] \(player.name) → \(card.rank)/\(card.suit)")

        // Check bela after the card is removed (partner must still be in hand)
        checkBelaOnPlay(player: player, card: card)

        if playedCards.count < players.count {
            currentPlayerIndex = nextIndex(after: currentPlayerIndex)
            maybeAskCurrentPlayerBotToPlay()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.clearTrickAndAdvance()
            }
        }
    }

    private func illegalReason(card: Card, hand: [Card]) -> String {
        guard let leadSuit = playedCards.first?.card.suit else { return "It's not your turn.".localized }
        let leadCards   = hand.filter { $0.suit == leadSuit }
        let trumpsInHand = hand.filter { $0.suit == trump }
        if !leadCards.isEmpty    { return "You must follow suit!".localized }
        if !trumpsInHand.isEmpty { return "You must play a trump card!".localized }
        return "You can't play that card!".localized
    }

    private func maybeAskCurrentPlayerBotToPlay() {
        let p = players[currentPlayerIndex]
        if p.isBot { bot(for: p)?.playCard() }
    }

    // MARK: provjere
    func nextIndex(after index: Int) -> Int { (index + 1) % players.count }

    func playedCard(for playerIndex: Int) -> Card? {
        playedCards.first { $0.playerIndex == playerIndex }?.card
    }

    var currentPlayer: Player { players[currentPlayerIndex] }

    func cardValue(_ card: Card) -> Int {
        card.suit == trump ? (trumpCardValues[card.rank] ?? 0) : (cardValues[card.rank] ?? 0)
    }

    // MARK: pobjednik stiha
    // FIX 2: determineWinnerOfTrick is correct as written, but clarified with comments.
    // Trump cards always beat non-trump. Among trump cards, trump rank order applies.
    // If no trump played, highest card of lead suit wins.
    private func determineWinnerOfTrick(_ trick: [PlayedCard]) -> Int {
        guard !trick.isEmpty else { return dealerIndex }

        let trumpSuit = trump

        let trOrd: [String: Int] = [
            "7": 0, "8": 1, "baba": 2, "kralj": 3,
            "10": 4, "as": 5, "9": 6, "decko": 7
        ]
        let nonTrOrd: [String: Int] = [
            "7": 0, "8": 1, "9": 2, "10": 3,
            "decko": 4, "baba": 5, "kralj": 6, "as": 7
        ]

        func strength(_ card: Card) -> Int {
            if let ts = trumpSuit, card.suit == ts {
                return trOrd[card.rank] ?? 0
            }
            return nonTrOrd[card.rank] ?? 0
        }

        // Trumps always win over non-trumps
        if let ts = trumpSuit {
            let trumpsPlayed = trick.filter { $0.card.suit == ts }
            if !trumpsPlayed.isEmpty {
                return trumpsPlayed.max(by: { strength($0.card) < strength($1.card) })!.playerIndex
            }
        }

        // No trump played: highest card of lead suit wins
        let leadSuit = trick.first!.card.suit
        let leadCards = trick.filter { $0.card.suit == leadSuit }
        return leadCards.max(by: { strength($0.card) < strength($1.card) })!.playerIndex
    }

    // MARK: dobitak stiha zbroj bodova
    // FIX 2: scoreTrick correctly uses cardValue() which already respects trump suit.
    private func scoreTrick(_ trick: [PlayedCard], winnerIndex: Int) {
        let pts = trick.reduce(0) { $0 + cardValue($1.card) }
        if team(for: winnerIndex) == 1 {
            roundScoreTeam1 += pts
        } else {
            roundScoreTeam2 += pts
        }
    }

    // MARK: zadnji stih
    // FIX 3: The fall (pad) mechanic now correctly compares TOTAL points
    // (tricks + melds) for the calling team vs the opposing team,
    // in accordance with standard Belot rules.
    private func finalizeRoundScores(lastWinnerIndex: Int) {
        // +10 za zadnji stih
        if team(for: lastWinnerIndex) == 1 {
            roundScoreTeam1 += 10
        } else {
            roundScoreTeam2 += 10
        }

        let trumpChooserIndex = players.firstIndex(where: { $0.id == trumpChooser?.id }) ?? 0
        let callerTeam = team(for: trumpChooserIndex)

        // Trick-only points at end of round (including last-trick bonus)
        let trickT1 = roundScoreTeam1
        let trickT2 = roundScoreTeam2

        // Total meld points (sequences + bela if called) pending for each team
        let meldT1 = pendingMeldTeam1
        let meldT2 = pendingMeldTeam2

        // FIX 3: Fall is determined by comparing TOTAL points (tricks + melds).
        // The calling team must have strictly MORE total points than the opponent.
        let totalT1 = trickT1 + meldT1
        let totalT2 = trickT2 + meldT2

        let callerFell: Bool
        if callerTeam == 1 {
            // Caller falls if they don't have strictly more total points
            callerFell = totalT1 <= totalT2
        } else {
            callerFell = totalT2 <= totalT1
        }

        let allMelds = meldT1 + meldT2

        if callerFell {

            let callerTrickPointsRaw = (callerTeam == 1) ? trickT1 - 10 : trickT2 - 10

            let callerGotZeroTricks: Bool
            if callerTeam == 1 {

                let lastTrickIsCallerTeam = (team(for: lastWinnerIndex) == 1)
                callerGotZeroTricks = lastTrickIsCallerTeam ? (trickT1 == 10) : (trickT1 == 0)
            } else {
                let lastTrickIsCallerTeam = (team(for: lastWinnerIndex) == 2)
                callerGotZeroTricks = lastTrickIsCallerTeam ? (trickT2 == 10) : (trickT2 == 0)
            }

            if callerTeam == 1 {
                roundScoreTeam1 = 0
                roundScoreTeam2 = 162 + allMelds + (callerGotZeroTricks ? 100 : 0)
                pendingMeldTeam1 = 0
                pendingMeldTeam2 = allMelds
            } else {
                roundScoreTeam2 = 0
                roundScoreTeam1 = 162 + allMelds + (callerGotZeroTricks ? 100 : 0)
                pendingMeldTeam1 = allMelds
                pendingMeldTeam2 = 0
            }
            debugPrint("[FALL] caller=\(callerTeam) zeroTricks=\(callerGotZeroTricks) T1=\(roundScoreTeam1) T2=\(roundScoreTeam2)")
        } else {
            // No fall: each team gets their own trick points + their own meld points
            roundScoreTeam1 = trickT1 + meldT1
            roundScoreTeam2 = trickT2 + meldT2
        }

        totalScoreTeam1 += roundScoreTeam1
        totalScoreTeam2 += roundScoreTeam2
        debugPrint("[RoundEnd] T1=\(roundScoreTeam1) T2=\(roundScoreTeam2) | Total T1=\(totalScoreTeam1) T2=\(totalScoreTeam2)")
        checkForGameWinner()
    }

    private func checkForGameWinner() {
        if totalScoreTeam1 >= maxScore && totalScoreTeam1 > totalScoreTeam2 {
            gameWinner = 1; gameIsOver = true; onGameOver?(1)
        } else if totalScoreTeam2 >= maxScore && totalScoreTeam2 > totalScoreTeam1 {
            gameWinner = 2; gameIsOver = true; onGameOver?(2)
        }
    }

    // MARK: zapocni iducu rundu
    private func clearTrickAndAdvance() {
        let lastTrick = playedCards
        let winnerIndex = determineWinnerOfTrick(lastTrick)
        scoreTrick(lastTrick, winnerIndex: winnerIndex)
        playedCards.removeAll()

        guard !roundEnding else { return }

        let allEmpty = players.allSatisfy { hands[$0.id]?.isEmpty ?? true }
        if allEmpty {
            roundEnding = true
            finalizeRoundScores(lastWinnerIndex: winnerIndex)
            if !gameIsOver {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.endRoundAndAdvanceDealer()
                    self?.roundEnding = false
                }
            }
        } else {
            currentPlayerIndex = winnerIndex
            maybeAskCurrentPlayerBotToPlay()
        }
    }

    // MARK: sve karte
    func playableCards(for player: Player) -> [Card] {
        guard let hand = hands[player.id], currentPlayer.id == player.id else { return [] }
        guard let leadSuit = playedCards.first?.card.suit else { return hand }

        let ts = trump
        let nonTrOrd: [String: Int] = [
            "7": 0, "8": 1, "9": 2, "decko": 3, "baba": 4, "kralj": 5, "10": 6, "as": 7
        ]
        let trOrd: [String: Int] = [
            "7": 0, "8": 1, "baba": 2, "kralj": 3, "10": 4, "as": 5, "9": 6, "decko": 7
        ]
        func str(_ c: Card) -> Int { c.suit == ts ? (trOrd[c.rank] ?? 0) : (nonTrOrd[c.rank] ?? 0) }

        let highestLead = playedCards.filter { $0.card.suit == leadSuit }.map { $0.card }.max { str($0) < str($1) }
        let highestTrump: Card? = {
            guard let ts else { return nil }
            return playedCards.filter { $0.card.suit == ts }.map { $0.card }.max { str($0) < str($1) }
        }()

        // Prati boju
        let leadCards = hand.filter { $0.suit == leadSuit }
        if !leadCards.isEmpty {
            if let hl = highestLead {
                let stronger = leadCards.filter { str($0) > str(hl) }
                return stronger.isEmpty ? leadCards : stronger
            }
            return leadCards
        }

        // Adut ako nema boje
        let trumpsInHand = hand.filter { $0.suit == ts }
        if !trumpsInHand.isEmpty {
            if let ht = highestTrump {
                let stronger = trumpsInHand.filter { str($0) > str(ht) }
                return stronger.isEmpty ? trumpsInHand : stronger
            }
            return trumpsInHand
        }

        // Bilo sto
        return hand
    }
}
