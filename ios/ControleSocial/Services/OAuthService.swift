import Foundation
import AuthenticationServices

@Observable
@MainActor
class OAuthService: NSObject {
    var isAuthenticating = false
    var authError: String?

    private var webAuthSession: ASWebAuthenticationSession?

    private var backendURL: String {
        let url = Bundle.main.infoDictionary?["RORK_API_BASE_URL"] as? String ?? ""
        if !url.isEmpty { return url }
        if let envURL = ProcessInfo.processInfo.environment["EXPO_PUBLIC_RORK_API_BASE_URL"], !envURL.isEmpty {
            return envURL
        }
        return ""
    }

    func connectMeta(userId: String) async -> OAuthCallbackResult? {
        isAuthenticating = true
        authError = nil
        defer { isAuthenticating = false }

        let startURL = "\(backendURL)/api/oauth/meta/start?userId=\(userId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? userId)"

        guard let url = URL(string: startURL) else {
            authError = "URL de autenticação inválida"
            return nil
        }

        do {
            let callbackURL = try await startWebAuth(url: url, callbackScheme: "controlesocial")
            return parseCallback(callbackURL)
        } catch {
            if (error as NSError).code != ASWebAuthenticationSessionError.canceledLogin.rawValue {
                authError = "Erro na autenticação: \(error.localizedDescription)"
            }
            return nil
        }
    }

    func connectTikTok(userId: String) async -> OAuthCallbackResult? {
        isAuthenticating = true
        authError = nil
        defer { isAuthenticating = false }

        let startURL = "\(backendURL)/api/oauth/tiktok/start?userId=\(userId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? userId)"

        guard let url = URL(string: startURL) else {
            authError = "URL de autenticação inválida"
            return nil
        }

        do {
            let callbackURL = try await startWebAuth(url: url, callbackScheme: "controlesocial")
            return parseCallback(callbackURL)
        } catch {
            if (error as NSError).code != ASWebAuthenticationSessionError.canceledLogin.rawValue {
                authError = "Erro na autenticação: \(error.localizedDescription)"
            }
            return nil
        }
    }

    private func startWebAuth(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: SupabaseError.apiError("No callback URL received"))
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.webAuthSession = session
            session.start()
        }
    }

    private func parseCallback(_ url: URL) -> OAuthCallbackResult? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            authError = "Resposta inválida"
            return nil
        }

        let queryItems = components.queryItems ?? []
        let success = queryItems.first(where: { $0.name == "success" })?.value == "true"
        let platform = queryItems.first(where: { $0.name == "platform" })?.value
        let connected = queryItems.first(where: { $0.name == "connected" })?.value
        let accountName = queryItems.first(where: { $0.name == "account_name" })?.value
        let errorMsg = queryItems.first(where: { $0.name == "error" })?.value

        if !success {
            authError = errorMsg ?? "Falha na autenticação"
            return nil
        }

        return OAuthCallbackResult(
            success: success,
            platform: platform ?? "",
            connectedPlatforms: connected?.split(separator: ",").map(String.init) ?? [],
            accountName: accountName
        )
    }
}

extension OAuthService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            ASPresentationAnchor()
        }
    }
}

nonisolated struct OAuthCallbackResult: Sendable {
    let success: Bool
    let platform: String
    let connectedPlatforms: [String]
    let accountName: String?
}
