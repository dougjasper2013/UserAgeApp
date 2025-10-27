//
//  ContentView.swift
//  UserAgeApp
//
//  Created by Douglas Jasper on 2025-10-27.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = UserViewModel()
    @State private var editName: String = ""
    @State private var editAge: String = ""

    var body: some View {
        NavigationView {
            Form {
                // Search bar
                Section {
                    TextField("Search by name...", text: $viewModel.searchText)
                        .textFieldStyle(.roundedBorder)
                }

                // All Users list
                Section(header: Text("All Users")) {
                    List {
                        ForEach(viewModel.filteredUsers) { user in
                            VStack(alignment: .leading) {
                                Text(user.name).bold()
                                Text("Age: \(user.age)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .onTapGesture {
                                viewModel.selectedUser = user
                                editName = user.name
                                editAge = "\(user.age)"
                                viewModel.isEditing = true
                            }
                        }
                        .onDelete { indexSet in
                            // Map filtered indices to actual indices in users array
                            let actualIndexes = IndexSet(indexSet.compactMap { filteredIndex in
                                viewModel.users.firstIndex(where: { $0.id == viewModel.filteredUsers[filteredIndex].id })
                            })
                            viewModel.deleteUser(at: actualIndexes)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .frame(minHeight: 150)
                }

                // Enter user info
                Section(header: Text("Enter your info")) {
                    TextField("Name", text: $viewModel.name)
                    TextField("Age", text: $viewModel.ageText)
                        .keyboardType(.numberPad)

                    Button("Save") {
                        viewModel.save()
                    }
                }
            }
            .navigationTitle("User Info")
            .onAppear { viewModel.fetchAll() }
            .sheet(isPresented: $viewModel.isEditing) {
                VStack(spacing: 20) {
                    Text("Edit User")
                        .font(.title2)

                    TextField("Name", text: $editName)
                        .textFieldStyle(.roundedBorder)

                    TextField("Age", text: $editAge)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)

                    Button("Save Changes") {
                        viewModel.updateUser(newName: editName, newAgeText: editAge)
                    }
                    .padding(.top)

                    Button("Cancel", role: .cancel) {
                        viewModel.isEditing = false
                    }
                }
                .padding()
            }
        }
    }
}
#Preview {
    ContentView()
}
