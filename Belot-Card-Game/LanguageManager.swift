// MARK: prevadanje rijeci pomocu skripte
import Foundation
import SwiftUI
import Combine

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published public var currentLanguage: String = UserDefaults.standard.string(forKey: "language") ?? (Locale.current.language.languageCode?.identifier ?? "en")
    @Published var bundle: Bundle = .main
    
    private init() {
        setLanguage(currentLanguage)
    }
    
    func setLanguage(_ code: String) {
        UserDefaults.standard.set(code, forKey: "language")
        currentLanguage = code
        
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let newBundle = Bundle(path: path) {
            bundle = newBundle
        } else {
            bundle = .main
        }
    }
    
    static var appLanguage: String {
        UserDefaults.standard.string(forKey: "language") ?? (Locale.current.language.languageCode?.identifier ?? "en")
    }
}

extension String {
    // Only keys present in Localizable.strings are detected by this method,
    // not keys that exist only in .xcstrings files.
    var localized: String {
        NSLocalizedString(self, tableName: nil, bundle: LanguageManager.shared.bundle, value: self, comment: "")
    }
}
