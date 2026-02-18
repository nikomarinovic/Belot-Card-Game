import SwiftUI

@main
struct Belot_Card_GameApp: App {
    
    @AppStorage("username") private var username: String = ""
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @AppStorage("language") private var language: String = "English"
    
    init() {
        let code = language == "Croatian" ? "hr" : "en"
        LanguageManager.shared.setLanguage(code)
    }
    
    var body: some Scene {
        WindowGroup {
            if username.isEmpty {
                ProfileSetupView()
                    .preferredColorScheme(.light)
            } else {
                ContentView()
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            }
        }
    }
}
