//
//  TodoStore.swift
//  OpenCodeClient
//

import Foundation
import Observation

@Observable
@MainActor
final class TodoStore {
    var sessionTodos: [String: [TodoItem]] = [:]
}
