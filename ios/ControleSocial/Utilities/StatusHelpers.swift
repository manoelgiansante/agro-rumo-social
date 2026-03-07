import SwiftUI

extension PostStatus {
    var displayName: String {
        switch self {
        case .pending: return "Pendente"
        case .generating: return "Gerando"
        case .ready: return "Pronto"
        case .review: return "Em Revisão"
        case .publishing: return "Publicando"
        case .published: return "Publicado"
        case .failed: return "Falhou"
        case .rejected: return "Rejeitado"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .generating: return "sparkles"
        case .ready: return "checkmark.circle"
        case .review: return "eye"
        case .publishing: return "arrow.up.circle"
        case .published: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .secondary
        case .generating: return .orange
        case .ready: return .blue
        case .review: return .yellow
        case .publishing: return .blue
        case .published: return .green
        case .failed: return .red
        case .rejected: return .red
        }
    }
}

extension PlatformStatus {
    var displayName: String {
        switch self {
        case .pending: return "Pendente"
        case .published: return "Publicado"
        case .failed: return "Falhou"
        case .skipped: return "Ignorado"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .published: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .skipped: return "minus.circle"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .secondary
        case .published: return .green
        case .failed: return .red
        case .skipped: return .secondary
        }
    }
}

extension PostCategory {
    var tintColor: Color {
        switch self {
        case .dicaManutencao: return .orange
        case .curiosidadeAgro: return .green
        case .economiaCombustivel: return .red
        case .gestaoFazenda: return .blue
        case .pecuaria: return .brown
        case .motivacionalAgro: return .yellow
        case .appShowcase: return .purple
        }
    }
}

struct NumberFormatter {
    static func compact(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        }
        return "\(value)"
    }
}
