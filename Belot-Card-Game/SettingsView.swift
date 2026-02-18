import SwiftUI

struct SettingsView: View {
    let onGoHome: () -> Void
    let onOpenBelaBlok: () -> Void
    
    @AppStorage("username") private var username: String = "username"
    @AppStorage("avatar") private var avatar: String = "avatar1"
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @AppStorage("vibrationsOn") private var vibrationsOn: Bool = true
    @AppStorage("SoundOn") private var SoundOn: Bool = true
    @AppStorage("language") private var language: String = "English"
    @AppStorage("cardStyle") private var cardStyle: String = "mađarice"
    
    @AppStorage("weScore") private var weScore: Int = 0
    @AppStorage("youScore") private var youScore: Int = 0
    @AppStorage("roundsData") private var roundsData: Data = Data()
    @AppStorage("maxPoints") private var maxPoints: Int = 1001
    
    @State private var showingMenuView: Bool = false
    @State private var showingProfileSetupView: Bool = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                // pozadina za dark ili light mode
                (isDarkMode ? Color(red: 0.1, green: 0.1, blue: 0.12) : Color.white)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Settings".localized)
                            .font(.system(size: 40))
                            .bold()
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut) {
                                showingMenuView.toggle()
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.gray)
                        }
                    }
                    .padding()
                    
                    // MARK: uredi profil
                    Text("Edit Profile:".localized)
                        .font(.system(size: 23))
                        .bold()
                        .padding(.horizontal,20)
                        .padding(.top,-15)
                    
                    HStack {
                        Image(avatar)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                        Text(username)
                            .padding(10)
                            .font(.system(size: 20))
                            .bold()
                    }
                    .onTapGesture {
                        if vibrationsOn{
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                        showingProfileSetupView = true
                    }
                    .padding(.top,0)
                    .padding(.horizontal,30)
                    
                    //MARK: dark mode
                    HStack {
                        Text("Dark Mode:".localized)
                            .font(.system(size: 23))
                            .bold()
                            Spacer()
                        Toggle("", isOn: $isDarkMode)
                            .labelsHidden()
                    }
                    .padding(.top,-5)
                    .padding(.horizontal,20)
                    
                    //MARK: vibracije on off
                    .padding(.top, 20)
                    HStack{
                        Text("Vibrations:".localized)
                            .font(.system(size:23 ))
                            .bold()
                            Spacer()
                        Toggle("", isOn: $vibrationsOn)
                            .labelsHidden()
                    }
                    .padding(.horizontal,20)
                    
                    //MARK: zvuk on off
                    HStack{
                        Text("Sound:".localized)
                            .font(.system(size:23 ))
                            .bold()
                            Spacer()
                        Toggle("", isOn: $SoundOn)
                            .labelsHidden()
                    }
                    .padding(.horizontal,20)
                    
                    //MARK: jezik
                    HStack {
                        Text("Language:".localized)
                            .font(.system(size: 23))
                            .bold()
                        Spacer()
                        
                        HStack(spacing: 15) {
                            // eng zastava
                            Button(action: {
                                language = "English"
                                LanguageManager.shared.setLanguage("en")
                            }) {
                                Image("uk_flag")
                                    .resizable()
                                    .cornerRadius(3)
                                    .frame(width: 50, height: 30)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(language == "English" ? Color.blue : Color.clear, lineWidth: 3)
                                    )

                            }
                            
                            // hr zastava
                            Button(action: {
                                language = "Croatian"
                                LanguageManager.shared.setLanguage("hr")
                            }) {
                                Image("croatia_flag")
                                    .resizable()
                                    .cornerRadius(3)
                                    .frame(width: 50, height: 30)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(language == "Croatian" ? Color.blue : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // MARK: izgled karata
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Playing Card Type:".localized)
                            .font(.system(size: 23))
                            .bold()
                            .padding(.bottom, 10)
                        
                        VStack(spacing: 10) {
                            Button(action: {
                                cardStyle = "mađarice"
                            }) {
                                HStack(spacing: 8) {
                                    Image("as_herc")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 90)
                                        .shadow(radius: 5)
                                        .cornerRadius(5)

                                    Image("as_pik")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 90)
                                        .shadow(radius: 5)
                                        .cornerRadius(5)
                                    
                                    Image("as_tref")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 90)
                                        .shadow(radius: 5)
                                        .cornerRadius(5)

                                    Image("as_karo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 90)
                                        .shadow(radius: 5)
                                        .cornerRadius(5)
                                }
                                .padding(10)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(cardStyle == "mađarice" ? Color.blue : Color.clear, lineWidth: 3)
                                )
                            }
                            
                            Button(action: {
                                cardStyle = "poker"
                            }) {
                                HStack(spacing: 8) {
                                    Image("as_herc")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 90)
                                        .shadow(radius: 5)
                                        .cornerRadius(5)
                                        .opacity(0.5)

                                    Image("as_pik")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 90)
                                        .shadow(radius: 5)
                                        .cornerRadius(5)
                                        .opacity(0.5)

                                    Image("as_tref")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 90)
                                        .shadow(radius: 5)
                                        .cornerRadius(5)
                                        .opacity(0.5)

                                    Image("as_karo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 90)
                                        .shadow(radius: 5)
                                        .cornerRadius(5)
                                        .opacity(0.5)
                                }
                                .padding(10)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(cardStyle == "poker" ? Color.blue : Color.clear, lineWidth: 3)
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal,20)
                    
                    // MARK: izbrisi account gumb
                    HStack {
                        Spacer()
                        Button(action: {
                            if vibrationsOn{
                                let generator = UIImpactFeedbackGenerator(style: .heavy)
                                generator.impactOccurred()
                            }
                            showDeleteConfirmation = true
                        }) {
                            Text("Delete Account".localized)
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                                .bold()
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .alert("Are you sure you want to delete your account? You will lose all data.".localized, isPresented: $showDeleteConfirmation) {
                            Button("Cancel".localized, role: .cancel) { }
                            Button("Delete".localized, role: .destructive) {
                                // Clear all AppStorage values
                                username = ""
                                avatar = "avatar1"
                                isDarkMode = false
                                vibrationsOn = true
                                language = "English"
                                weScore = 0
                                youScore = 0
                                roundsData = Data() 
                                maxPoints = 1001
                                cardStyle="mađarice"
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 100)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // MARK: meni
                if showingMenuView {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                showingMenuView = false
                            }
                        }
                        .zIndex(0)
                    
                    MenuView(onClose: {
                        withAnimation(.easeInOut) { showingMenuView = false }
                    }, onOpenSettings: {
                        withAnimation(.easeInOut) { showingMenuView = false }
                    }, onGoHome: {
                        withAnimation(.easeInOut) { showingMenuView = false }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onGoHome() }
                    }, onBelaBlok: {
                        withAnimation(.easeInOut) { showingMenuView = false }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onOpenBelaBlok() }
                    })
                    .frame(width: geometry.size.width / 2) 
                    .frame(maxHeight: .infinity)
                    .background(isDarkMode ? Color(red: 0.1, green: 0.1, blue: 0.12) : Color.white)
                    .shadow(radius: 5)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
                }            }
        }
        .sheet(isPresented: $showingProfileSetupView) {
            ProfileSetupView()
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}


#Preview {
    SettingsView(onGoHome: { }, onOpenBelaBlok: { })
}

