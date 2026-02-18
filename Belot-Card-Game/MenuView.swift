import SwiftUI

struct MenuView: View {
    let onClose: () -> Void
    let onOpenSettings: () -> Void
    let onGoHome: () -> Void
    let onBelaBlok: () -> Void
    
    @AppStorage("username") private var username: String = "username"
    @AppStorage("avatar") private var avatar: String = "avatar1"
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @AppStorage("vibrationsOn") private var vibrationsOn: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(avatar)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .shadow(radius: 10)

                Text(username)
                    .padding(10)
                    .font(.system(size: max(14,30-CGFloat(username.count))))
                    .bold()
                    .lineLimit(1) // onemogucava da ide text u dva reda
                    .minimumScaleFactor(0.5) // dopusta da se text sam smanjuje
            }
            .padding(.top,80)
            
            Divider()
                .frame(height: 1)
                .background(isDarkMode ? Color.white.opacity(1):Color.black.opacity(1) )
            //MARK: home gumb
                Button(action: {
                    onGoHome()
                }){
                    Text("Home".localized)
                }
                    .buttonStyle(MenuButtonStyle(isDarkMode: isDarkMode))
            //MARK: bela blok gumb
                Button(action: {
                    onBelaBlok()
                }){
                    Text("Bela Blok")
                }
                    .buttonStyle(MenuButtonStyle(isDarkMode: isDarkMode))
            //MARK: O nama gumb
                Button(action: {
                    //otvara o nama dio ekrana
                }){
                    Text("About Us".localized)
                }
                    .buttonStyle(MenuButtonStyle(isDarkMode: isDarkMode))
            //MARK: gumb za postavke
                Button(action: {
                    onOpenSettings()
                }){
                    Text("Settings".localized)
                }
                    .buttonStyle(MenuButtonStyle(isDarkMode: isDarkMode))
            
            Spacer()
        }
        .padding(.horizontal)
        .background(isDarkMode ? Color(red: 0.08, green: 0.08, blue: 0.1) : Color.white)
        .edgesIgnoringSafeArea(.all) // osigurava da dode odozgora do dole skrina
    }
}


//stil za sve gubove koji su u meniju
struct MenuButtonStyle: ButtonStyle {
    
    var isDarkMode: Bool = false
    @AppStorage("vibrationsOn") private var vibrationsOn: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 22))
            .padding(.vertical, 3)
            .padding(.horizontal, 0)
            .foregroundColor(configuration.isPressed ? .gray : (isDarkMode ? .white : .black))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    if vibrationsOn{
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                }
            }
    }
}
#Preview {
    ContentView()
}
