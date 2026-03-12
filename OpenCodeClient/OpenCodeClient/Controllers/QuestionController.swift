//
//  QuestionController.swift
//  OpenCodeClient
//

import Foundation

enum QuestionController {
    static func fromPendingRequests(_ requests: [QuestionRequest]) -> [QuestionRequest] {
        requests
    }

    static func parseAskedEvent(properties: [String: AnyCodable]) -> QuestionRequest? {
        let raw = properties.mapValues { $0.value }

        if let request = decodeQuestionRequest(raw) {
            return request
        }

        if let nested = raw["request"] as? [String: Any] {
            var merged = nested
            if merged["id"] == nil {
                merged["id"] = raw["id"] ?? raw["questionID"] ?? raw["requestID"]
            }
            if merged["sessionID"] == nil {
                merged["sessionID"] = raw["sessionID"]
            }
            if merged["tool"] == nil {
                merged["tool"] = raw["tool"]
            }
            return decodeQuestionRequest(merged)
        }

        return nil
    }

    static func applyResolvedEvent(properties: [String: AnyCodable], to questions: inout [QuestionRequest]) {
        let requestID = (properties["requestID"]?.value as? String) ?? (properties["id"]?.value as? String)
        guard let requestID else { return }

        if let sessionID = properties["sessionID"]?.value as? String {
            questions.removeAll { $0.sessionID == sessionID && $0.id == requestID }
            return
        }

        questions.removeAll { $0.id == requestID }
    }

    private static func decodeQuestionRequest(_ object: Any) -> QuestionRequest? {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object),
              let request = try? JSONDecoder().decode(QuestionRequest.self, from: data) else {
            return nil
        }
        return request
    }
}
