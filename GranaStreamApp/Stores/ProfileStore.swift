import SwiftUI
import Combine

final class ProfileStore: ObservableObject {
    @AppStorage("profileName") private var storedName: String = ""
    @AppStorage("profileEmail") private var storedEmail: String = ""
    @AppStorage("profilePhone") private var storedPhone: String = ""

    var profileName: String {
        get { storedName }
        set {
            objectWillChange.send()
            storedName = newValue
        }
    }

    var profileEmail: String {
        get { storedEmail }
        set {
            objectWillChange.send()
            storedEmail = newValue
        }
    }

    var profilePhone: String {
        get { storedPhone }
        set {
            objectWillChange.send()
            storedPhone = newValue
        }
    }

    func save(name: String, email: String, phone: String) {
        profileName = name
        profileEmail = email
        profilePhone = phone
    }
}
