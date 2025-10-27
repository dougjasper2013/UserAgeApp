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

    private let dbRef = Database.database().reference()
    private let usersPath = "users"

    // SAVE user
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
            if let error = error {
                print("Error saving to Realtime DB: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.name = ""
                    self.ageText = ""
                }
                self.fetchAll()
            }
        }
    }

    // FETCH all users
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

            DispatchQueue.main.async {
                self.users = newUsers
            }
        }
    }

    // ✅ DELETE a user
    func deleteUser(at offsets: IndexSet) {
        for index in offsets {
            let user = users[index]
            dbRef.child(usersPath).child(user.id).removeValue { error, _ in
                if let error = error {
                    print("Error deleting user: \(error)")
                } else {
                    self.fetchAll() // refresh list after delete
                }
            }
        }
    }
}
