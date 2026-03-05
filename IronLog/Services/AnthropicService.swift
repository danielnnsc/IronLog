import Foundation

// MARK: - Program Action (returned by Claude)

struct ProgramAction: Decodable {
    enum Kind: String, Decodable {
        case switchProgram
        case addExercises
        case addSession
    }

    var kind: Kind
    var programType: String?        // ProgramType rawValue for switchProgram / addSession
    var exercisesToAdd: [String]?   // UUID strings for addExercises
    var targetSessionNames: [String]? // Which sessions to add exercises to
    var explanation: String         // Human-readable description shown to the user
}

// MARK: - Service

struct AnthropicService {

    static let shared = AnthropicService()
    private init() {}

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    /// Sends a natural language customization request to Claude and returns a ProgramAction.
    func customize(
        userMessage: String,
        currentProgram: ProgramType,
        sessionNames: [String]
    ) async throws -> ProgramAction {

        let systemPrompt = """
        You are a fitness program assistant for IronLog, an iOS strength training app.
        The user's current program is: \(currentProgram.rawValue)
        Their current sessions are: \(sessionNames.joined(separator: ", "))
        Available program types: upperLower, pushPullLegs, fullBody, muscleGroupSplit, stronglifts, arnoldSplit, phul
        Available core/abs exercise UUIDs:
          cableCrunch: E0000027-0000-0000-0000-000000000000
          hangingLegRaise: E0000028-0000-0000-0000-000000000000
          abWheelRollout: E0000029-0000-0000-0000-000000000000
          plank: E0000030-0000-0000-0000-000000000000
          russianTwist: E0000031-0000-0000-0000-000000000000
          declineSitUp: E0000032-0000-0000-0000-000000000000

        Respond ONLY with valid JSON (no markdown, no extra text) matching this exact schema:
        {
          "kind": "switchProgram" | "addExercises" | "addSession",
          "programType": "<ProgramType rawValue or null>",
          "exercisesToAdd": ["<UUID string>", ...] or null,
          "targetSessionNames": ["<session name>", ...] or null,
          "explanation": "<friendly 1-2 sentence explanation of what will change>"
        }

        Rules:
        - Use "switchProgram" if the user wants to change their whole program.
        - Use "addExercises" if the user wants to add specific exercises (e.g. abs) to existing sessions.
        - Use "addSession" if the user wants to bolt on a session type from a different program.
        - For "addExercises", pick 2-3 relevant exercises from the UUID list above.
        - For "targetSessionNames", pick 1-2 of the user's existing sessions that are most appropriate.
        - Keep the explanation concise and encouraging.
        """

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 512,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AnthropicError.badResponse(statusCode, body)
        }

        // Parse the Claude response envelope
        let envelope = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        guard let text = envelope.content.first?.text else {
            throw AnthropicError.emptyResponse
        }

        // Decode the JSON payload Claude returned
        guard let jsonData = text.data(using: .utf8) else {
            throw AnthropicError.invalidJSON
        }
        return try JSONDecoder().decode(ProgramAction.self, from: jsonData)
    }
}

// MARK: - Response Models

private struct ClaudeResponse: Decodable {
    struct ContentBlock: Decodable { let text: String }
    let content: [ContentBlock]
}

// MARK: - Errors

enum AnthropicError: LocalizedError {
    case badResponse(Int, String), emptyResponse, invalidJSON

    var errorDescription: String? {
        switch self {
        case .badResponse(let code, let body):
            return "API error \(code): \(body.prefix(200))"
        case .emptyResponse: return "The AI returned an empty response."
        case .invalidJSON:  return "The AI returned an unexpected format."
        }
    }
}
