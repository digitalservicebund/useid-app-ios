import Foundation

@propertyWrapper
struct UserDefault<T> {
    
    let userDefaults: UserDefaults
    let key: StorageKey
    let defaultValue: T
    
    init(userDefaults: UserDefaults = UserDefaults.standard,
         key: StorageKey,
         defaultValue: T) {
        self.userDefaults = userDefaults
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T {
        get { return userDefaults.object(forKey: key.rawValue) as? T ?? defaultValue }
        set { userDefaults.set(newValue, forKey: key.rawValue) }
    }
}

enum StorageKey: String {
    case setupCompleted
}

class StorageManager: StorageManagerType {
    
    @UserDefault var setupCompleted: Bool
    
    init(userDefaults: UserDefaults = .standard) {
        _setupCompleted = UserDefault(userDefaults: userDefaults, key: .setupCompleted, defaultValue: false)
    }
    
}
