import SwiftUI
import Combine

// MARK: model igraca
struct Player: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let isBot: Bool
    let team: Int // 1 = moj tim, 2 = drugi tim
    let avatar: String
}

struct LobbyView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPrivate = false
    
    @AppStorage("username") private var username: String = ""
    @AppStorage("vibrationsOn") private var vibrationsOn: Bool = true
    @AppStorage("avatar") private var avatar: String = "avatar1"
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @AppStorage("gameScore") private var gameScore: Int = 1001
    
    private let maxPlayers = 4
    @State private var roomName: String = ""
    @State private var players: [Player] = []
    @State private var isGameStarted = false
    
    // MARK: random imena za sobe
    func generateRandomRoomName() -> String {
        let adjectives = ["Brzi", "Sretni", "Hrabri", "Veliki", "Mali","Plavi", "Zeleni", "Veseli", "Pametni", "Smireni","Jaki", "Ludi", "Briljantni", "Topli","Debeli","Mršavi","Visoki","Niski","Lukavi","Tihi","Opasni","Brutalni","Vatreni","Zlatni","Smrdljivi","Namazani","Stari","Bogati","Musavi","Zeznuti", "Sposobni","Nesposobni","Mesnati","Upitni","Dobri","Bahati"]
        let nouns = ["Tigar", "Zmaj", "Orao", "Lav", "Burek","Vuk", "Medvjed", "Sokol", "Jelen", "Mačak","Pas", "Lisac", "Konj", "Galeb","Herc", "Tref","Pik","Svinjac","Kamen","Duh","Štakor","Pauk","Jastog","Inćun","Kralj","Labud","Bubreg","Sladoled","Pilić","Profić","As","Frajer","Ris","Doktor","Majstor","Krumpir","Paradajz"]
        
        return "\(adjectives.randomElement() ?? "Brzi")-\(nouns.randomElement() ?? "Tigar")"
    }
    
    // MARK: generator imena za botove
    func randomBotName() -> String {
        let names = [
            "Buraz", "Kralj", "Kolega", "Mravojed", "Kompić", "Kraljica", "Žohar", "Žac",
            "Zoki", "Gmaz", "Boki", "Đuro", "Bepi", "Mićo", "Nikša", "Domi", "Cobi",
            "Pero", "Joža", "Ivek", "Jurica", "Zlatko",
            "Toni", "Laki", "Regi", "Bane", "Cico", "Šef", "Dule", "Gagi", "Ćale",
            "Pajo", "Flek", "Braco", "Žile", "Kizo", "Roki", "Vlado", "Miki", "Leko",
            "Deki", "Neno", "Joca", "Bubi", "Tomi", "Bobo", "Lino", "Riki", "Fićo",
            "Maki", "Gogo", "Šime", "Rado", "Mitro", "Viki", "Đoko", "Zvrk", "Fredi",
            "Bobi", "Luka", "Ivo", "Niki", "Roko", "Jurek", "Tošo", "Žarko",
            "Dado", "Milo", "Bari", "Flaš", "Tomić", "Nedo", "Peko", "Šarko"
        ]
        return names.randomElement() ?? "Bot"
    }
    
    // MARK: generator avatara za botove
    func randomBotAvatar() -> String {
        let avatars = ["bat", "bear", "beaver", "dog", "gorilla", "kangaroo",
                       "penguin", "pig", "rabbit", "shark", "sloth", "turtle",
                       "walrus", "wild-boar", "wolf"]
        return avatars.randomElement() ?? "bear"
    }
    
    // MARK: glavni view
    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: informacije o igri
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Game name".localized)
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .italic()
                    
                    Text(roomName)
                        .font(.system(size: 24))
                        .bold()
                        .foregroundColor(isDarkMode ? .white : .black)
                }
                
                Spacer()
                
                Text("\(gameScore)")
                    .font(.system(size: 24))
                    .bold()
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.top, 3)
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
            
            // MARK: lista igraca
            VStack(spacing: 10) {

                ForEach([0, 2], id: \.self) { index in
                    if players.indices.contains(index) {
                        playerRow(player: players[index], label: index == 0 ? "You".localized : "Teammate".localized)
                    }
                }
                
                Text("VS")
                    .font(.system(size: 16))
                    .bold()
                    .foregroundColor(isDarkMode ? .white : .black)
                    .padding(.vertical, 4)
                
                ForEach([1, 3], id: \.self) { index in
                    if players.indices.contains(index) {
                        playerRow(player: players[index], label: "Opponent".localized)
                    }
                }
            }
            .padding(.top, 50)
            
            Spacer()
            
            // MARK: gumbovi
            HStack {
                Button(action: {
                    if vibrationsOn {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                    dismiss()
                }) {
                    Text("Leave".localized)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.25)
                                               : Color.gray.opacity(0.2))
                        .cornerRadius(12)
                }

                Spacer()

                Button(action: {
                    if vibrationsOn {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                    isGameStarted = true
                }) {
                    Text("Start Game".localized)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .fullScreenCover(isPresented: $isGameStarted) {
                    GameView(players: players)
                }
            }
            .padding(.bottom, 40)
            .padding(.horizontal, 20)
        }
        .padding(.top, 70)
        .background(isDarkMode ? Color(red: 0.1, green: 0.1, blue: 0.12) : Color.white)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            if roomName.isEmpty {
                roomName = generateRandomRoomName()
            }
            if players.isEmpty {
                setupPlayers()
            }
        }
    }
    
    // MARK: red igraca
    @ViewBuilder
    private func playerRow(player: Player, label: String) -> some View {
        HStack(spacing: 12) {
            Spacer().frame(width: 10)
            
            Image(player.avatar)
                .resizable()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.headline)
                    .bold()
                    .foregroundColor(isDarkMode ? .white : .black)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
        .background(isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.25)
                                : Color.gray.opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
    
    // MARK: svi igraci
    // redosljed mora odgovarati GameView pozicijama:
    // index 0 = dolje
    // index 1 = desno
    // index 2 = gore
    // index 3 = lijevo
    func setupPlayers() {
        let human = Player(name: username.isEmpty ? "You" : username,
                           isBot: false,
                           team: 1,
                           avatar: avatar)
        
        let opponent1 = Player(name: randomBotName(),
                               isBot: true,
                               team: 2,
                               avatar: randomBotAvatar())
        
        let teammate = Player(name: randomBotName(),
                              isBot: true,
                              team: 1,
                              avatar: randomBotAvatar())
        
        let opponent2 = Player(name: randomBotName(),
                               isBot: true,
                               team: 2,
                               avatar: randomBotAvatar())
        
        players = [human, opponent1, teammate, opponent2]
    }
}

#Preview {
    LobbyView()
}
