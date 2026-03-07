//
//  AIBuildersAudioClient.swift
//  OpenCodeClient
//

import Foundation
import os

struct TranscriptionResponse: Codable {
    let requestID: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
        case text
    }
}

enum AIBuildersAudioError: Error {
    case invalidBaseURL
    case missingToken
    case invalidResponse
    case httpError(statusCode: Int, body: Data)
}

enum AIBuildersAudioClient {
    private final class TaskMetricsCollector: NSObject, URLSessionTaskDelegate {
        private(set) var metrics: URLSessionTaskMetrics?

        func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            didFinishCollecting metrics: URLSessionTaskMetrics
        ) {
            self.metrics = metrics
        }
    }

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "OpenCodeClient",
        category: "SpeechProfile"
    )

    private static func elapsedMs(since start: TimeInterval) -> Int {
        max(0, Int((ProcessInfo.processInfo.systemUptime - start) * 1000))
    }

    private static func durationMs(start: Date?, end: Date?) -> Int? {
        guard let start, let end else { return nil }
        return max(0, Int((end.timeIntervalSince(start)) * 1000))
    }

    private static func logNetworkMetrics(_ metrics: URLSessionTaskMetrics?) {
        guard
            let transaction = metrics?.transactionMetrics.last
        else {
            logger.notice("[SpeechProfile] transcribe metrics unavailable")
            return
        }

        let dnsMs = durationMs(start: transaction.domainLookupStartDate, end: transaction.domainLookupEndDate) ?? -1
        let connectMs = durationMs(start: transaction.connectStartDate, end: transaction.connectEndDate) ?? -1
        let tlsMs = durationMs(start: transaction.secureConnectionStartDate, end: transaction.secureConnectionEndDate) ?? -1
        let requestSendMs = durationMs(start: transaction.requestStartDate, end: transaction.requestEndDate) ?? -1
        let ttfbMs = durationMs(start: transaction.requestEndDate, end: transaction.responseStartDate) ?? -1
        let responseMs = durationMs(start: transaction.responseStartDate, end: transaction.responseEndDate) ?? -1
        let totalTransactionMs = durationMs(start: transaction.fetchStartDate, end: transaction.responseEndDate) ?? -1

        logger.notice(
            "[SpeechProfile] transcribe metrics dnsMs=\(dnsMs, privacy: .public) connectMs=\(connectMs, privacy: .public) tlsMs=\(tlsMs, privacy: .public) sendMs=\(requestSendMs, privacy: .public) ttfbMs=\(ttfbMs, privacy: .public) responseMs=\(responseMs, privacy: .public) transactionMs=\(totalTransactionMs, privacy: .public) reusedConnection=\(transaction.isReusedConnection, privacy: .public) networkProtocol=\(transaction.networkProtocolName ?? "unknown", privacy: .public)"
        )
    }

    static func transcribe(
        baseURL: String,
        token: String,
        audioFileURL: URL,
        language: String? = nil,
        prompt: String? = nil,
        terms: String? = nil
    ) async throws -> TranscriptionResponse {
        let trimmedBase = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBase.isEmpty else { throw AIBuildersAudioError.invalidBaseURL }
        guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw AIBuildersAudioError.missingToken }
        let transcribeStart = ProcessInfo.processInfo.systemUptime

        let normalizedBase: String = {
            if trimmedBase.hasPrefix("http://") || trimmedBase.hasPrefix("https://") { return trimmedBase }
            return "https://\(trimmedBase)"
        }()

        guard let url = URL(string: "\(normalizedBase)/v1/audio/transcriptions") else {
            throw AIBuildersAudioError.invalidBaseURL
        }

        let fileName = audioFileURL.lastPathComponent.isEmpty ? "audio.m4a" : audioFileURL.lastPathComponent
        let fileBytes = (try? audioFileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? -1
        logger.notice("[SpeechProfile] transcribe begin host=\(url.host ?? "unknown", privacy: .public) file=\(fileName, privacy: .public) fileBytes=\(fileBytes, privacy: .public)")

        let readStart = ProcessInfo.processInfo.systemUptime
        let audioData = try Data(contentsOf: audioFileURL)
        logger.notice("[SpeechProfile] transcribe readAudio ms=\(elapsedMs(since: readStart), privacy: .public) bytes=\(audioData.count, privacy: .public)")

        let multipartStart = ProcessInfo.processInfo.systemUptime
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        func append(_ string: String) {
            body.append(Data(string.utf8))
        }

        if let language, !language.isEmpty {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"language\"\r\n\r\n")
            append("\(language)\r\n")
        }
        if let prompt, !prompt.isEmpty {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n")
            append("\(prompt)\r\n")
        }
        if let terms, !terms.isEmpty {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"terms\"\r\n\r\n")
            append("\(terms)\r\n")
        }

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"audio_file\"; filename=\"\(fileName)\"\r\n")
        append("Content-Type: application/octet-stream\r\n\r\n")
        body.append(audioData)
        append("\r\n")
        append("--\(boundary)--\r\n")
        logger.notice("[SpeechProfile] transcribe buildMultipart ms=\(elapsedMs(since: multipartStart), privacy: .public) payloadBytes=\(body.count, privacy: .public)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let metricsCollector = TaskMetricsCollector()
        let networkStart = ProcessInfo.processInfo.systemUptime
        let (data, response) = try await URLSession.shared.data(for: request, delegate: metricsCollector)
        logger.notice("[SpeechProfile] transcribe network ms=\(elapsedMs(since: networkStart), privacy: .public) responseBytes=\(data.count, privacy: .public)")
        logNetworkMetrics(metricsCollector.metrics)

        guard let http = response as? HTTPURLResponse else {
            throw AIBuildersAudioError.invalidResponse
        }
        guard http.statusCode < 400 else {
            logger.error("[SpeechProfile] transcribe httpError status=\(http.statusCode, privacy: .public) totalMs=\(elapsedMs(since: transcribeStart), privacy: .public)")
            throw AIBuildersAudioError.httpError(statusCode: http.statusCode, body: data)
        }

        let decodeStart = ProcessInfo.processInfo.systemUptime
        let decoded = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        logger.notice("[SpeechProfile] transcribe decode ms=\(elapsedMs(since: decodeStart), privacy: .public) textChars=\(decoded.text.count, privacy: .public) totalMs=\(elapsedMs(since: transcribeStart), privacy: .public) requestID=\(decoded.requestID, privacy: .public)")
        return decoded
    }

    /// 测试 AI Builder 连接（调用 embeddings API，验证 token 有效）
    static func testConnection(baseURL: String, token: String) async throws {
        let trimmedBase = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBase.isEmpty else { throw AIBuildersAudioError.invalidBaseURL }
        guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw AIBuildersAudioError.missingToken }

        let normalizedBase: String = {
            if trimmedBase.hasPrefix("http://") || trimmedBase.hasPrefix("https://") { return trimmedBase }
            return "https://\(trimmedBase)"
        }()

        guard let url = URL(string: "\(normalizedBase)/v1/embeddings") else {
            throw AIBuildersAudioError.invalidBaseURL
        }

        let body = try JSONEncoder().encode(["input": "ok"])
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIBuildersAudioError.invalidResponse
        }
        guard http.statusCode < 400 else {
            throw AIBuildersAudioError.httpError(statusCode: http.statusCode, body: data)
        }
    }
}
