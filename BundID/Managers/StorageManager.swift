import Foundation

struct StorageManager: StorageManagerType {
    
    private var userDefaults: UserDefaults
    
    var setupCompleted: Bool {
        userDefaults.bool(forKey: StorageKey.setupCompleted.rawValue)
    }
    
    func updateSetupCompleted(_ newValue: Bool) {
        userDefaults.set(newValue, forKey: StorageKey.setupCompleted.rawValue)
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
}
