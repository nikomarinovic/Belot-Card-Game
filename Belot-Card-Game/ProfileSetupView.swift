import SwiftUI

struct ProfileSetupView: View {
    
    // Local storage
    @AppStorage("username") private var username: String = ""
    @AppStorage("avatar") private var avatar: String = "avatar1"
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @AppStorage("vibrationsOn") private var vibrationsOn: Bool = true
    
    // privremene vrijednosti
    @State private var tempUsername: String = ""
    @State private var selectedAvatar: String = "avatar1"
    
    @Environment(\.dismiss) private var dismiss
    
    // imena za avatare
    let avatars = ["avatar1","avatar2","avatar3","avatar4","avatar5","avatar6","avatar7","avatar8","avatar9"]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            // pozadina za dark ili light mode
            (isDarkMode ? Color(red: 0.1, green: 0.1, blue: 0.12) : Color.white)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                
                Text(username.isEmpty ? "Set up your profile".localized : "Edit your profile".localized)
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(isDarkMode ? .white : .black)
                // upisati username
                Text("Enter a username".localized)
                    .font(.title2)
                    .bold()
                    .padding(.top, 30)
                    .foregroundColor(isDarkMode ? .white : .black)
                
                TextField("", text: $tempUsername, prompt: Text("Username".localized).foregroundColor(.gray))
                    .padding(15)
                    .background(isDarkMode ? Color(.darkGray) : Color.white)
                    .foregroundColor(isDarkMode ? .white : .black)
                    .accentColor(isDarkMode ? .white : .black)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 3)
                    )
                    .padding(.horizontal)
                    .padding()
                    .padding(.top,-10)
                    .onChange(of: tempUsername) { oldValue, newValue in
                        if newValue.count > 10 {
                            tempUsername = String(newValue.prefix(10))
                        }
                    }
                // odabrati avatara
                Text("Choose an avatar".localized)
                    .font(.title2)
                    .bold()
                    .foregroundColor(isDarkMode ? .white : .black)
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(avatars, id: \.self) { avatarName in
                        Image(avatarName)
                            .resizable()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(selectedAvatar == avatarName ? Color.blue : Color.clear, lineWidth: 4)
                            )
                            .onTapGesture {
                                selectedAvatar = avatarName
                            }
                    }
                }
                .padding(.bottom, 10)
                
                Button(action: {
                    if vibrationsOn{
                        let generator = UIImpactFeedbackGenerator(style: .soft)
                        generator.impactOccurred()
                    }
                    //zamjenjujemo stari username s novim i spremamo ga u localstorage
                    if !tempUsername.isEmpty && tempUsername != username {
                        username = tempUsername
                    }
                    avatar = selectedAvatar
                    dismiss()
                }) {
                    Text("Save".localized)
                        .font(.title2)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .padding()
            .onAppear {
                tempUsername = username
                selectedAvatar = avatar
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

#Preview {
    ProfileSetupView()
}
