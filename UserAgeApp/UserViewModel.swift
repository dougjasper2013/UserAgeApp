import Foundation
import FirebaseDatabase
import SwiftUI

struct UserInfo: Identifiable, Codable {
    var id: String
    var name: String
    var age: Int
}

class UserViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var ageText: String = ""
    @Published var users: [UserInfo] = []

    // Search
    @Published var searchText: String = ""

    // Editing
    @Published var selectedUser: UserInfo?
    @Published var isEditing: Bool = false

    private let dbRef = Database.database().reference()
    private let usersPath = "users"

    // Computed property for filtered users
    var filteredUsers: [UserInfo] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    func save() {
        guard let age = Int(ageText), !name.isEmpty else { return }

        let id = UUID().uuidString
        let userInfo = UserInfo(id: id, name: name, age: age)

        let data: [String: Any] = [
            "id": userInfo.id,
            "name": userInfo.name,
            "age": userInfo.age
        ]

        dbRef.child(usersPath).child(id).setValue(data) { error, _ in
            if error == nil {
                DispatchQueue.main.async {
                    self.name = ""
                    self.ageText = ""
                    self.searchText = ""
                }
                self.fetchAll()
            }
        }
    }

    func updateUser(newName: String, newAgeText: String) {
        guard let user = selectedUser,
              let age = Int(newAgeText),
              !newName.isEmpty else { return }

        let updatedData: [String: Any] = [
            "id": user.id,
            "name": newName,
            "age": age
        ]

        dbRef.child(usersPath).child(user.id).updateChildValues(updatedData) { error, _ in
            if error == nil {
                self.fetchAll()
                DispatchQueue.main.async {
                    self.selectedUser = nil
                    self.isEditing = false
                }
            }
        }
    }

    func fetchAll() {
        dbRef.child(usersPath).observeSingleEvent(of: .value) { snapshot in
            var newUsers: [UserInfo] = []

            if let dict = snapshot.value as? [String: Any] {
                for user in dict.values {
                    if let data = user as? [String: Any],
                       let id = data["id"] as? String,
                       let name = data["name"] as? String,
                       let age = data["age"] as? Int {
                        newUsers.append(UserInfo(id: id, name: name, age: age))
                    }
                }
            }

            // Sort alphabetically
            newUsers.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            DispatchQueue.main.async {
                self.users = newUsers
            }
        }
    }

    func deleteUser(at offsets: IndexSet) {
        for index in offsets {
            let user = users[index]
            dbRef.child(usersPath).child(user.id).removeValue { error, _ in
                if error == nil { self.fetchAll() }
            }
        }
    }
}
