import SwiftUI
import Combine
//da se zatvori tipkovnica kada se klike negdje na screen
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView: View {
    
    @AppStorage("username") private var username: String = ""
    @AppStorage("avatar") private var avatar: String = "avatar1"
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @AppStorage("vibrationsOn") private var vibrationsOn: Bool = true
    @AppStorage("language") private var language: String = "English"
    @AppStorage("gameScore") private var gameScore: Int = 1001

    @State private var showingProfileSetupView = false
    @State private var showingBelaBlokView = false
    @State private var showingMenuView = false
    @State private var showingSettingsView = false
    @State private var searchText: String = ""
    @State private var showLobby = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showScorePicker = false
    @State private var selectedScore: Int? = nil
        
    @ObservedObject var languageManager = LanguageManager.shared

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                
                // ovo je da pozadina promjeni boju izmedu dark i light mode-a
                (isDarkMode ? Color(red: 0.1, green: 0.1, blue: 0.12) : Color.white)
                    .edgesIgnoringSafeArea(.all)
                
                // MARK: Glavni ekran
                VStack {
                    //MARK: Prikazi avatara i username
                    HStack {
                        Image(avatar)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 95, height: 95)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                        
                        Text(username)
                            .padding(10)
                            .font(.system(size: 25))
                            .bold()
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut) {
                                showingMenuView.toggle()
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        }
                    }
                    .onTapGesture {
                        if vibrationsOn{
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                        showingProfileSetupView = true
                    }
                    .padding()
                    Spacer()
                    // MARK: - Nova igra gumb
                    VStack {
                        Button(action: {
                            if vibrationsOn{
                                let generator = UIImpactFeedbackGenerator(style: .heavy)
                                generator.impactOccurred()
                            }
                            showScorePicker=true
                        }) {
                            Text("Create Game".localized)
                                .font(.system(size: 25, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 22)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                        .padding(.horizontal, 20)
                        //MARK: biranje bodova
                        .sheet(isPresented: $showScorePicker) {
                            VStack(spacing: 25) {
                                Text("New Game".localized)
                                    .font(.system(size: 28))
                                    .bold()
                                    .padding(.top, 32)
                                    .padding(.bottom, 15)
                                
                                Text("Select Game Score:".localized)
                                    .font(.title2)
                                    .padding(.bottom, 20)
                                
                                HStack(spacing: 15) {
                                    ForEach([501, 701, 1001], id: \.self) { score in
                                        Button(action: {
                                            if vibrationsOn {
                                                let generator = UIImpactFeedbackGenerator(style: .soft)
                                                generator.impactOccurred()
                                            }
                                            gameScore = score         
                                            showScorePicker = false
                                            showLobby = true
                                        }) {
                                            Text("\(score)")
                                                .font(.system(size: 24, weight: .semibold))
                                                .padding(.horizontal, score == 1001 ? 30 : 20)
                                                .padding(.vertical, 12)
                                                .background(Color.blue.opacity(0.85))
                                                .foregroundColor(.white)
                                                .cornerRadius(16)
                                                .shadow(radius: 3)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .cornerRadius(20)
                            .presentationDetents([.height(250)])
                            .presentationDragIndicator(.visible)
                            .scrollContentBackground(.hidden)
                            .background(
                                (isDarkMode ? Color(red: 0.1, green: 0.1, blue: 0.12) : Color.white)
                                    .edgesIgnoringSafeArea(.all)
                            )
                        }
                    }
                    .fullScreenCover(isPresented: $showLobby) {
                        LobbyView()
                    }
                }
                // MARK: Bocni meni
                if showingMenuView {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                showingMenuView = false
                            }
                        }
                    
                    MenuView(onClose: {
                        withAnimation(.easeInOut) {
                            showingMenuView = false
                        }
                    }, onOpenSettings: {
                        withAnimation(.easeInOut) {
                            showingMenuView = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingSettingsView = true
                        }
                    }, onGoHome: {
                        withAnimation(.easeInOut) {
                            showingMenuView = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingSettingsView = false
                            showingProfileSetupView = false
                        }
                    },onBelaBlok: {
                        withAnimation(.easeInOut) {
                            showingMenuView = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingSettingsView = false
                            showingProfileSetupView = false
                            showingBelaBlokView = true
                        }
                    })
                    .frame(width: geometry.size.width / 2)
                    .frame(maxHeight: .infinity)
                    .background(isDarkMode ? Color(red: 0.1, green: 0.1, blue: 0.12) : Color.white)
                    .shadow(radius: 5)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
                }
            }
        }
        // full screen kada se prikazuje settings
        .fullScreenCover(isPresented: $showingSettingsView) {
            SettingsView(onGoHome: {
                showingSettingsView = false
                // prikazuje samo set up screen ako je username prazan
                if username.isEmpty {
                    showingProfileSetupView = true
                }
            }, onOpenBelaBlok: {
                // zatvara settings i onda otvara Bela Blok
                showingSettingsView = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingBelaBlokView = true
                }
            })
        }
        .fullScreenCover(isPresented: $showingBelaBlokView, onDismiss: {
            showingSettingsView = false
            // prikazuje samo set up screen ako je username prazan
            if username.isEmpty {
                showingProfileSetupView = true
            }
        }) {
            BelaBlokView()
        }
        .sheet(isPresented: $showingProfileSetupView) {
            ProfileSetupView()
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onChange(of: showingBelaBlokView) { oldValue, newValue in
            if oldValue == true && newValue == false {
                // kada se belablok zatvori treba se i settings zatvorit
                showingSettingsView = false
                showingProfileSetupView = false
            }
        }
    }
}

#Preview {
    ContentView()
}
