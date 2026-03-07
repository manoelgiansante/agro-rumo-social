import Foundation
import AuthenticationServices
import CryptoKit

@Observable
@MainActor
class AuthService {
    static let shared = AuthService()

    var currentUser: AuthUser?
    var userProfile: UserProfile?
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?

    private let keychainAccessToken = "cs_access_token"
    private let keychainRefreshToken = "cs_refresh_token"

    private init() {}

    var baseURL: String { Config.SUPABASE_URL }
    var anonKey: String { Config.SUPABASE_ANON_KEY }

    func checkSession() async {
        isLoading = true
        defer { isLoading = false }

        guard let token = UserDefaults.standard.string(forKey: keychainAccessToken),
              !token.isEmpty else {
            isAuthenticated = false
            return
        }

        do {
            let user = try await getUser(token: token)
            currentUser = user
            isAuthenticated = true
            await loadProfile(userId: user.id, token: token)
        } catch {
            if let refresh = UserDefaults.standard.string(forKey: keychainRefreshToken), !refresh.isEmpty {
                do {
                    let session = try await refreshSession(refreshToken: refresh)
                    saveSession(session)
                    currentUser = session.user
                    isAuthenticated = true
                    await loadProfile(userId: session.user.id, token: session.accessToken)
                } catch {
                    clearSession()
                }
            } else {
                clearSession()
            }
        }
    }

    var signUpSuccessMessage: String?

    func signUp(email: String, password: String, fullName: String) async throws {
        isLoading = true
        errorMessage = nil
        signUpSuccessMessage = nil
        defer { isLoading = false }

        let resolvedURL = baseURL.isEmpty ? "https://jxcnfyeemdltdfqtgbcl.supabase.co" : baseURL
        let resolvedKey = anonKey.isEmpty ? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4Y25meWVlbWRsdGRmcXRnYmNsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1MDQwNTksImV4cCI6MjA4NDA4MDA1OX0.MEqgaUHb0cDVoDrXY6rc1F6YJLxzbpNiks-SFRCg2go" : anonKey

        print("[AUTH] SignUp starting for: \(email)")
        print("[AUTH] Using URL: \(resolvedURL)")

        guard let url = URL(string: "\(resolvedURL)/auth/v1/signup") else {
            errorMessage = "URL inválida"
            throw AuthError.serverError(errorMessage!)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(resolvedKey, forHTTPHeaderField: "apikey")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": ["full_name": fullName]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            print("[AUTH] SignUp network error: \(urlError.code) - \(urlError.localizedDescription)")
            errorMessage = "Erro de conexão (\(urlError.code.rawValue)). Verifique sua internet."
            throw AuthError.networkError
        } catch {
            print("[AUTH] SignUp unknown error: \(error)")
            errorMessage = "Erro de conexão. Verifique sua internet."
            throw AuthError.networkError
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            errorMessage = "Erro de conexão inesperado."
            throw AuthError.networkError
        }

        let responseString = String(data: data, encoding: .utf8) ?? "no body"
        print("[AUTH] SignUp response \(httpResponse.statusCode): \(responseString)")

        if httpResponse.statusCode >= 400 {
            let errResp = try? JSONDecoder().decode(AuthErrorResponse.self, from: data)
            let msg = errResp?.displayMessage ?? "Erro ao criar conta (código \(httpResponse.statusCode))"
            errorMessage = translateError(msg)
            throw AuthError.serverError(errorMessage!)
        }

        do {
            let session = try JSONDecoder().decode(AuthSession.self, from: data)
            if !session.accessToken.isEmpty {
                print("[AUTH] SignUp got session token, user: \(session.user.id)")
                saveSession(session)
                currentUser = session.user
                isAuthenticated = true
                await createProfile(userId: session.user.id, fullName: fullName, token: session.accessToken)
                return
            }
        } catch {
            print("[AUTH] SignUp session decode failed: \(error)")
        }

        if let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let identities = jsonObj["identities"] as? [[String: Any]],
           identities.isEmpty {
            errorMessage = "Este email já está cadastrado. Tente fazer login."
            throw AuthError.serverError(errorMessage!)
        }

        signUpSuccessMessage = "Conta criada! Verifique seu email para confirmar o cadastro."
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let resolvedURL = baseURL.isEmpty ? "https://jxcnfyeemdltdfqtgbcl.supabase.co" : baseURL
        let resolvedKey = anonKey.isEmpty ? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4Y25meWVlbWRsdGRmcXRnYmNsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1MDQwNTksImV4cCI6MjA4NDA4MDA1OX0.MEqgaUHb0cDVoDrXY6rc1F6YJLxzbpNiks-SFRCg2go" : anonKey

        print("[AUTH] SignIn starting for: \(email)")
        print("[AUTH] Using URL: \(resolvedURL)")

        guard let url = URL(string: "\(resolvedURL)/auth/v1/token?grant_type=password") else {
            errorMessage = "URL inválida"
            throw AuthError.serverError(errorMessage!)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(resolvedKey, forHTTPHeaderField: "apikey")
        request.timeoutInterval = 30

        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            print("[AUTH] SignIn network error: \(urlError.code) - \(urlError.localizedDescription)")
            errorMessage = "Erro de conexão (\(urlError.code.rawValue)). Verifique sua internet."
            throw AuthError.networkError
        } catch {
            print("[AUTH] SignIn unknown error: \(error)")
            errorMessage = "Erro de conexão. Verifique sua internet."
            throw AuthError.networkError
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            errorMessage = "Erro de conexão inesperado."
            throw AuthError.networkError
        }

        let responseString = String(data: data, encoding: .utf8) ?? "no body"
        print("[AUTH] SignIn response \(httpResponse.statusCode): \(responseString)")

        if httpResponse.statusCode >= 400 {
            let errResp = try? JSONDecoder().decode(AuthErrorResponse.self, from: data)
            let msg = errResp?.displayMessage ?? "Erro ao fazer login (código \(httpResponse.statusCode))"
            errorMessage = translateError(msg)
            throw AuthError.serverError(errorMessage!)
        }

        do {
            let session = try JSONDecoder().decode(AuthSession.self, from: data)
            print("[AUTH] SignIn got session, user: \(session.user.id)")
            saveSession(session)
            currentUser = session.user
            isAuthenticated = true
            await loadProfile(userId: session.user.id, token: session.accessToken)
        } catch {
            print("[AUTH] SignIn decode error: \(error)")
            errorMessage = "Erro ao processar resposta do servidor."
            throw AuthError.serverError(errorMessage!)
        }
    }

    private var currentNonce: String?

    func signInWithApple(authorization: ASAuthorization) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = credential.identityToken,
              let idToken = String(data: identityTokenData, encoding: .utf8) else {
            errorMessage = "Não foi possível obter as credenciais da Apple."
            throw AuthError.serverError(errorMessage!)
        }

        let resolvedURL = baseURL.isEmpty ? "https://jxcnfyeemdltdfqtgbcl.supabase.co" : baseURL
        let resolvedKey = anonKey.isEmpty ? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4Y25meWVlbWRsdGRmcXRnYmNsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1MDQwNTksImV4cCI6MjA4NDA4MDA1OX0.MEqgaUHb0cDVoDrXY6rc1F6YJLxzbpNiks-SFRCg2go" : anonKey

        print("[AUTH] Apple SignIn starting")

        guard let url = URL(string: "\(resolvedURL)/auth/v1/token?grant_type=id_token") else {
            errorMessage = "URL inválida"
            throw AuthError.serverError(errorMessage!)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(resolvedKey, forHTTPHeaderField: "apikey")
        request.timeoutInterval = 30

        var body: [String: Any] = [
            "provider": "apple",
            "id_token": idToken
        ]
        if let nonce = currentNonce {
            body["nonce"] = nonce
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            errorMessage = "Erro de conexão. Verifique sua internet."
            throw AuthError.networkError
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            errorMessage = "Erro de conexão inesperado."
            throw AuthError.networkError
        }

        if httpResponse.statusCode >= 400 {
            let errResp = try? JSONDecoder().decode(AuthErrorResponse.self, from: data)
            let msg = errResp?.displayMessage ?? "Erro ao autenticar com Apple (código \(httpResponse.statusCode))"
            errorMessage = translateError(msg)
            throw AuthError.serverError(errorMessage!)
        }

        do {
            let session = try JSONDecoder().decode(AuthSession.self, from: data)
            saveSession(session)
            currentUser = session.user
            isAuthenticated = true

            let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            if !fullName.isEmpty {
                await createProfile(userId: session.user.id, fullName: fullName, token: session.accessToken)
            } else {
                await loadProfile(userId: session.user.id, token: session.accessToken)
            }
        } catch {
            errorMessage = "Erro ao processar resposta do servidor."
            throw AuthError.serverError(errorMessage!)
        }
    }

    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }

    func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce.")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    func signOut() {
        clearSession()
    }

    func getAccessToken() -> String? {
        UserDefaults.standard.string(forKey: keychainAccessToken)
    }

    private func getUser(token: String) async throws -> AuthUser {
        let resolvedURL = baseURL.isEmpty ? "https://jxcnfyeemdltdfqtgbcl.supabase.co" : baseURL
        let resolvedKey = anonKey.isEmpty ? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4Y25meWVlbWRsdGRmcXRnYmNsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1MDQwNTksImV4cCI6MjA4NDA4MDA1OX0.MEqgaUHb0cDVoDrXY6rc1F6YJLxzbpNiks-SFRCg2go" : anonKey
        guard let url = URL(string: "\(resolvedURL)/auth/v1/user") else { throw AuthError.networkError }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(resolvedKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.invalidSession
        }
        return try JSONDecoder().decode(AuthUser.self, from: data)
    }

    private func refreshSession(refreshToken: String) async throws -> AuthSession {
        let resolvedURL = baseURL.isEmpty ? "https://jxcnfyeemdltdfqtgbcl.supabase.co" : baseURL
        let resolvedKey = anonKey.isEmpty ? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4Y25meWVlbWRsdGRmcXRnYmNsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1MDQwNTksImV4cCI6MjA4NDA4MDA1OX0.MEqgaUHb0cDVoDrXY6rc1F6YJLxzbpNiks-SFRCg2go" : anonKey
        guard let url = URL(string: "\(resolvedURL)/auth/v1/token?grant_type=refresh_token") else { throw AuthError.networkError }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(resolvedKey, forHTTPHeaderField: "apikey")

        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.invalidSession
        }
        return try JSONDecoder().decode(AuthSession.self, from: data)
    }

    private func loadProfile(userId: String, token: String) async {
        let resolvedURL = baseURL.isEmpty ? "https://jxcnfyeemdltdfqtgbcl.supabase.co" : baseURL
        let resolvedKey = anonKey.isEmpty ? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4Y25meWVlbWRsdGRmcXRnYmNsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1MDQwNTksImV4cCI6MjA4NDA4MDA1OX0.MEqgaUHb0cDVoDrXY6rc1F6YJLxzbpNiks-SFRCg2go" : anonKey
        let urlString = "\(resolvedURL)/rest/v1/user_profiles?id=eq.\(userId)&select=*"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(resolvedKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let profiles = try decoder.decode([UserProfile].self, from: data)
            userProfile = profiles.first
        } catch {
            // Profile might not exist yet
        }
    }

    private func createProfile(userId: String, fullName: String, token: String) async {
        let resolvedURL = baseURL.isEmpty ? "https://jxcnfyeemdltdfqtgbcl.supabase.co" : baseURL
        let resolvedKey = anonKey.isEmpty ? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4Y25meWVlbWRsdGRmcXRnYmNsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1MDQwNTksImV4cCI6MjA4NDA4MDA1OX0.MEqgaUHb0cDVoDrXY6rc1F6YJLxzbpNiks-SFRCg2go" : anonKey
        let urlString = "\(resolvedURL)/rest/v1/user_profiles"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.setValue(resolvedKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: String] = [
            "id": userId,
            "full_name": fullName,
            "subscription_status": "trial"
        ]
        request.httpBody = try? JSONEncoder().encode(body)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let profiles = try decoder.decode([UserProfile].self, from: data)
            userProfile = profiles.first
        } catch {}
    }

    private func saveSession(_ session: AuthSession) {
        UserDefaults.standard.set(session.accessToken, forKey: keychainAccessToken)
        UserDefaults.standard.set(session.refreshToken, forKey: keychainRefreshToken)
    }

    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: keychainAccessToken)
        UserDefaults.standard.removeObject(forKey: keychainRefreshToken)
        currentUser = nil
        userProfile = nil
        isAuthenticated = false
    }

    private func translateError(_ msg: String) -> String {
        let lower = msg.lowercased()
        if lower.contains("invalid login credentials") || lower.contains("invalid_credentials") {
            return "Email ou senha incorretos"
        } else if lower.contains("already registered") || lower.contains("already been registered") || lower.contains("user_already_exists") {
            return "Este email já está cadastrado. Tente fazer login."
        } else if lower.contains("password should be") || lower.contains("weak_password") {
            return "A senha deve ter pelo menos 6 caracteres"
        } else if lower.contains("invalid email") || lower.contains("unable to validate email") {
            return "Email inválido"
        } else if lower.contains("email not confirmed") {
            return "Email não confirmado. Verifique sua caixa de entrada."
        } else if lower.contains("rate limit") || lower.contains("too many requests") {
            return "Muitas tentativas. Aguarde um momento e tente novamente."
        } else if lower.contains("signup_disabled") {
            return "Cadastro temporariamente desabilitado."
        }
        return msg
    }
}

nonisolated enum AuthError: Error, Sendable {
    case networkError
    case invalidSession
    case serverError(String)

    var message: String {
        switch self {
        case .networkError: return "Erro de conexão"
        case .invalidSession: return "Sessão expirada"
        case .serverError(let msg): return msg
        }
    }
}
