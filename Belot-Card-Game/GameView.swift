import SwiftUI

// MARK: - GameView
struct GameView: View {

    let players: [Player]
    @StateObject private var manager: GameManager

    @State private var goHome          = false
    @State private var revealedAfterPass = false
    @State private var showExitAlert   = false
    @State private var showWinnerPopup = false
    @State private var winnerTeam      = 0
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @AppStorage("vibrationsOn") private var vibrationsOn: Bool = true
    @AppStorage("language") private var language: String = "English"
    @AppStorage("gameScore") private var gameScore: Int  = 1001
    @AppStorage("gamesWon")  private var gamesWon:  Int  = 0
    @AppStorage("gamesLost") private var gamesLost: Int  = 0

    init(players: [Player]) {
        self.players = players
        _manager = StateObject(wrappedValue: GameManager(players: players))
    }

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .bottom) {

                // MARK: glavni dio
                VStack(spacing: 0) {
                    scoreboardView.padding(.top, 8)
                    tableView.frame(maxWidth: .infinity, maxHeight: .infinity)

                    if !isTrumpSelectionActive {
                        Color.clear.frame(height: cardBoxHeight - 20)
                    }
                    if isTrumpSelectionActive {
                        TrumpSelectionView(
                            onChoose: { manager.chooseTrump(player: players[0], suit: $0) },
                            onPass: {
                                revealedAfterPass = true
                                manager.chooseTrump(player: players[0], suit: nil)
                            },
                            canPass: manager.dealerIndex != 0
                        )
                        .disabled(!isPlayersTurnToSelectTrump)
                        .opacity(isPlayersTurnToSelectTrump ? 1.0 : 0.5)
                        .padding(.horizontal, 16)
                    }
                }

                // MARK: prozori svi
                VStack(spacing: 0) {
                    Spacer()
                    CardBoxView(
                        hand: manager.hands[players[0].id] ?? [],
                        manager: manager,
                        player: players[0],
                        revealedAfterPass: revealedAfterPass
                    )
                    .offset(y: isTrumpSelectionActive ? -trumpSelectorHeight : -1)
                    .animation(isTrumpSelectionActive ? .easeInOut(duration: 0.3) : .none,
                               value: isTrumpSelectionActive)
                }
                .allowsHitTesting(!isTrumpSelectionActive || isPlayersTurnToSelectTrump)

                // provjera zvanja
                if manager.meldCheckingPhase {
                    meldCheckingOverlay
                }

                // zvanja rezultat
                if manager.meldShowPhase {
                    meldResultOverlay
                }

                // bela prompt
                if manager.showBelaPrompt {
                    belaPromptOverlay
                }

                // prikazi ako je neispravna karta bacena
                if let msg = manager.illegalCardMessage {
                    illegalToast(msg)
                }

                // pobjednicki popup
                if showWinnerPopup {
                    winnerOverlay
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Leave game?".localized, isPresented: $showExitAlert) {
            Button("Cancel".localized, role: .cancel) {}
            Button("Leave".localized, role: .destructive) {
                gamesLost += 1
                goHome = true
            }
        } message: { Text("Leaving counts as a loss!".localized) }
        .fullScreenCover(isPresented: $goHome) { ContentView() }
        .onChange(of: manager.trump) { newVal in
            if newVal == nil { revealedAfterPass = false }
        }
        .onChange(of: manager.trumpSelectionIndex) { _ in
            if manager.trump == nil { revealedAfterPass = false }
        }
        .onAppear {
            manager.maxScore = gameScore
            manager.onGameOver = { team in
                winnerTeam = team
                showWinnerPopup = true
                if team == 1 { gamesWon += 1 } else { gamesLost += 1 }
            }
        }
    }

    // MARK: bodovi
    private var scoreboardView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Tim 1
                VStack(spacing: 3) {
                    Text("We".localized)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                    // Bodovi runde + pending zvanja
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(manager.roundScoreTeam1)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                        if manager.pendingMeldTeam1 > 0 {
                            Button { manager.meldShowPhase = true } label: {
                                Text("+\(manager.pendingMeldTeam1)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.orange)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    Text("\(manager.totalScoreTeam1)")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)

                // MARK: Adut
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.white).shadow(radius: 3)
                            .overlay(Circle().stroke(Color.black.opacity(0.25), lineWidth: 2))
                            .frame(width: 68, height: 68)
                        if let t = manager.trump {
                            Image(t).resizable().scaledToFit().frame(width: 42, height: 56)
                        } else {
                            Image(systemName: "questionmark.circle")
                                .resizable().scaledToFit().frame(width: 34, height: 34)
                                .foregroundColor(.gray)
                        }
                    }
                    Text(manager.trump.map { $0.capitalized } ?? "?")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black.opacity(0.7))
                    Text(manager.trumpChooser?.name ?? " ")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)

                // Tim 2
                VStack(spacing: 3) {
                    Text("They".localized)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(manager.roundScoreTeam2)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                        if manager.pendingMeldTeam2 > 0 {
                            Button { manager.meldShowPhase = true } label: {
                                Text("+\(manager.pendingMeldTeam2)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.orange)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    Text("\(manager.totalScoreTeam2)")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal, 20)

            HStack {
                Spacer()
                Button { showExitAlert = true } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .resizable().frame(width: 24, height: 24)
                        .foregroundColor(.black).shadow(radius: 2)
                }
                .padding(.trailing, 20)
                .padding(.top, 8)
            }
        }
    }

    // MARK: igraci + karte display
    private var tableView: some View {
        VStack(spacing: 0) {
            // Gore: suigrac (index 2)
            VStack(spacing: 4) {
                Image(players[2].avatar)
                    .resizable().scaledToFit().frame(width: 54, height: 54)
                    .clipShape(Circle()).shadow(radius: 3)
                Text(players[2].name).font(.headline).bold().foregroundColor(.black)
                cardSlot(for: 2)
            }.padding(.top, 8)

            Spacer(minLength: 4)

            HStack {
                // Lijevi protivnik (index 3)
                HStack(spacing: 6) {
                    VStack(spacing: 3) {
                        Image(players[3].avatar)
                            .resizable().scaledToFit().frame(width: 48, height: 48)
                            .clipShape(Circle()).shadow(radius: 3)
                        Text(players[3].name).font(.subheadline).bold().foregroundColor(.black)
                    }
                    cardSlot(for: 3)
                }.padding(.leading, 14)

                Spacer()

                // Desni protivnik (index 1)
                HStack(spacing: 6) {
                    cardSlot(for: 1)
                    VStack(spacing: 3) {
                        Image(players[1].avatar)
                            .resizable().scaledToFit().frame(width: 48, height: 48)
                            .clipShape(Circle()).shadow(radius: 3)
                        Text(players[1].name).font(.subheadline).bold().foregroundColor(.black)
                    }
                }.padding(.trailing, 14)
            }

            Spacer(minLength: 4)

            // Igrač ja (index 0)
            cardSlot(for: 0).padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private func cardSlot(for idx: Int) -> some View {
        ZStack {
            if let c = manager.playedCard(for: idx) {
                Image(c.imageName)
                    .resizable().scaledToFit()
                    .frame(width: 56, height: 84).shadow(radius: 2)
            }
        }
        .frame(width: 56, height: 84)
        .allowsHitTesting(false)
    }

    // MARK: provjera zvanja
    private var meldCheckingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 18) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .scaleEffect(1.6)
                Text("Checking for declerations".localized)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.black)
            }
            .padding(36)
            .background(Color(white: 1))
            .cornerRadius(20)
            .shadow(radius: 14)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: manager.meldCheckingPhase)
    }

    // MARK: prikaz rezultata provjere zvanja
    private var meldResultOverlay: some View {
        ZStack {
            Color.black.opacity(0.52).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Naslov + X gumb
                    HStack {
                        Text("Declarations".localized)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                        Spacer()
                        Button { manager.meldShowPhase = false } label: {
                            Image(systemName: "xmark.circle.fill")
                                .resizable().frame(width: 28, height: 28)
                                .foregroundColor(.black.opacity(0.7))
                        }
                    }

                    if manager.playerMelds.isEmpty {
                        // Nema zvanja ni kod koga
                        Text("There were no declarations".localized)
                            .font(.system(size: 18))
                            .foregroundColor(.black.opacity(0.8))
                            .padding(.top, 8)
                    } else {
                        // Prikazuj samo zvanja tima koji ima jaca zvanja
                        let grouped = Dictionary(grouping: manager.playerMelds, by: { $0.playerIndex })

                        ForEach(grouped.keys.sorted(), id: \.self) { pIdx in
                            let melds  = grouped[pIdx]!
                            let pName  = manager.players[pIdx].name
                            let total  = melds.reduce(0) { $0 + $1.points }

                            VStack(alignment: .leading, spacing: 10) {
                                // Igrac + ukupni bodovi zvanja
                                HStack {
                                    Text(pName)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.black)
                                    Spacer()
                                    Text(.pts(total))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.black)
                                }

                                // Svako zvanje s kartama
                                ForEach(melds) { meld in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(meld.description)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.black.opacity(0.5))
                                            Spacer()
                                            Text(.pts(meld.points))
                                                .font(.system(size: 13))
                                                .foregroundColor(.black.opacity(0.6))
                                        }
                                        HStack(spacing: 6) {
                                            ForEach(meld.cards.sorted {
                                                (manager.rankOrder[$0.rank] ?? 0) < (manager.rankOrder[$1.rank] ?? 0)
                                            }) { card in
                                                Image(card.imageName)
                                                    .resizable().scaledToFit()
                                                    .frame(width: 40, height: 60)
                                                    .shadow(radius: 2)
                                            }
                                        }
                                    }
                                    .padding(10)
                                    .background(Color.white.opacity(0.7))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(14)
                            .background(Color.black.opacity(0.10))
                            .cornerRadius(16)
                            .padding(.horizontal, 2)
                        }

                        // Sažetak - tko dobiva i koliko
                        Divider().background(Color.white.opacity(0.3))
                        let winTeamName = manager.winningMeldTeam == 1 ? "We".localized : "They".localized
                        let winPts = manager.winningMeldTeam == 1 ? manager.pendingMeldTeam1 : manager.pendingMeldTeam2
                        Text(.getPoints(winTeamName, winPts))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: 360, maxHeight: 540)
            .background(Color(white: 1))
            .cornerRadius(22)
            .shadow(radius: 16)
            .padding(.horizontal, 20)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.35), value: manager.meldShowPhase)
    }

    // MARK: bela (posebno zvanje)
    private var belaPromptOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Call Bela?".localized)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text("You have the queen and king of trump (+20 points)".localized)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                HStack(spacing: 20) {
                    Button {
                        manager.declineBela()
                    } label: {
                        Text("No".localized)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 100, height: 44)
                            .background(Color.gray.opacity(0.7))
                            .cornerRadius(12)
                    }
                    Button {
                        manager.callBela(player: players[0])
                    } label: {
                        Text("Yes, Bela!".localized)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 120, height: 44)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(28)
            .background(Color(white: 0.15))
            .cornerRadius(20)
            .shadow(radius: 12)
            .padding(.horizontal, 40)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: manager.showBelaPrompt)
    }

    // MARK: nelegalan potez
    private func illegalToast(_ msg: String) -> some View {
        VStack {
            Spacer()
            Text(msg)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(Color.red.opacity(0.9))
                .cornerRadius(12).shadow(radius: 6)
                .padding(.bottom, cardBoxHeight + 14)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(), value: manager.illegalCardMessage)
    }

    // MARK: pobjednicki screen
    private var winnerOverlay: some View {
        ZStack {
            Color.black.opacity(0.52).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(winnerTeam == 1 ? "🏆 We won!".localized : "😔 They won!".localized)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.black).multilineTextAlignment(.center)
                Text("\(manager.totalScoreTeam1) : \(manager.totalScoreTeam2)")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.85))
                Button { goHome = true } label: {
                    Text(.backToMenu)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(winnerTeam == 1 ? .green : .red)
                        .padding(.horizontal, 28).padding(.vertical, 11)
                        .background(Color.white).cornerRadius(12)
                }
            }
            .padding(32)
            .background(winnerTeam == 1 ? Color.green.opacity(0.85) : Color.red.opacity(0.85))
            .cornerRadius(22).shadow(radius: 14)
            .transition(.scale).animation(.spring(), value: showWinnerPopup)
        }
    }

    // MARK: provjere
    private var trumpSelectorHeight: CGFloat { 95 }
    private var cardBoxHeight: CGFloat { 220 }

    private var isTrumpSelectionActive: Bool {
        manager.trump == nil && manager.trumpSelectionIndex != nil
    }
    private var isPlayersTurnToSelectTrump: Bool {
        guard manager.trump == nil, let si = manager.trumpSelectionIndex else { return false }
        return players.indices.contains(si) && players[si].id == players[0].id
    }
}

// MARK: display karata
struct CardBoxView: View {
    let hand: [Card]
    @ObservedObject var manager: GameManager
    let player: Player
    let revealedAfterPass: Bool

    private let W: CGFloat = 55
    private let H: CGFloat = 82

    private var isMyTurn: Bool { manager.currentPlayer.id == player.id }
    private var isMyTrumpTurn: Bool {
        guard let si = manager.trumpSelectionIndex else { return false }
        return manager.players[si].id == player.id
    }
    private var isActive: Bool { isMyTrumpTurn || (manager.trump != nil && isMyTurn) }

    var body: some View {
        VStack(spacing: 2) {
            Text(statusMessage())
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isActive ? .white : .black)
                .padding(.horizontal, 10).padding(.vertical, 2)
                .background(isActive ? Color.green : Color.clear)
                .cornerRadius(8).frame(height: 22)

            if !hand.isEmpty {
                VStack(spacing: 6) {
                    ForEach(0..<2) { row in
                        HStack(spacing: 10) {
                            ForEach(0..<4) { col in
                                let idx = row * 4 + col
                                if hand.indices.contains(idx) {
                                    let card = hand[idx]
                                    let hide = idx >= 6 && manager.trump == nil && !revealedAfterPass
                                    if hide {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: W, height: H)
                                    } else {
                                        cardButton(card: card)
                                    }
                                } else {
                                    Color.clear.frame(width: W, height: H)
                                }
                            }
                        }
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal, 20)
            }
        }
    }

    private func statusMessage() -> String {
        if let si = manager.trumpSelectionIndex {
            let sel = manager.players[si]
            if sel.id == player.id {
                return si == manager.dealerIndex ? "You must choose trump".localized : "Choose trump or pass".localized
            }
            return "\(sel.name) is deciding".localized
        }
        return isMyTurn ? "Your turn".localized : "\(manager.currentPlayer.name) is playing".localized
    }

    @ViewBuilder
    private func cardButton(card: Card) -> some View {
        let playPhase = manager.trump != nil && !manager.meldCheckingPhase && !manager.meldShowPhase
        Button {
            if playPhase && isMyTurn {
                manager.playCard(player: player, card: card)
            }
        } label: {
            Image(card.imageName)
                .resizable().scaledToFit()
                .frame(width: W, height: H).shadow(radius: 2)
        }
        .disabled(!playPhase || !isMyTurn)
    }
}

// MARK: - TrumpSelectionView
struct TrumpSelectionView: View {
    let onChoose: (String) -> Void
    let onPass: () -> Void
    let canPass: Bool
    private let suits = ["tref", "herc", "pik", "karo"]

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                ForEach(suits, id: \.self) { suit in
                    Button { onChoose(suit) } label: {
                        Image(suit).resizable().scaledToFit()
                            .frame(width: 35, height: 47).padding(8)
                            .background(Color.white).cornerRadius(8)
                            .shadow(color: .gray.opacity(0.2), radius: 2)
                    }
                }
                if canPass {
                    Button { onPass() } label: {
                        Text("Pass".localized)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 10).padding(.horizontal, 14)
                            .background(Color.gray).cornerRadius(8)
                    }
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
            .shadow(color: .gray.opacity(0.3), radius: 4))
    }
}

#Preview {
    GameView(players: [
        Player(name: "Ja",         isBot: false, team: 1, avatar: "bat"),
        Player(name: "Protivnik1", isBot: true,  team: 2, avatar: "shark"),
        Player(name: "Suigrac",    isBot: true,  team: 1, avatar: "penguin"),
        Player(name: "Protivnik2", isBot: true,  team: 2, avatar: "kangaroo")
    ])
}
