import Foundation

struct MockDataService {
    static func generatePosts() -> [Post] {
        let calendar = Calendar.current
        let now = Date()
        var posts: [Post] = []
        let categories = PostCategory.allCases

        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            let category = categories[i % categories.count]
            let status: PostStatus = i < 2 ? .ready : (i < 25 ? .published : .failed)
            let igStatus: PlatformStatus = status == .published ? .published : (status == .failed ? .failed : .pending)
            let fbStatus: PlatformStatus = status == .published ? .published : (status == .failed ? .failed : .pending)
            let tkStatus: PlatformStatus = status == .published ? .published : (i == 3 ? .failed : .pending)

            posts.append(Post(
                id: "post-\(i)",
                category: category,
                caption: captionFor(category),
                hashtags: "#agro #agronegocio #produtorrural #fazenda #agricultura #pecuaria #controledemaquina #gestaoagro #rumomaquinas #trator #campo #safra #agrobrasil #tecnologiaagro #produtividade",
                imageUrl: nil,
                imagePrompt: "Fotografia profissional de campo agrícola brasileiro",
                scheduledFor: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date)!,
                publishedAt: status == .published ? calendar.date(bySettingHour: 10, minute: 2, second: 0, of: date) : nil,
                status: status,
                instagramPostId: igStatus == .published ? "ig_\(i)" : nil,
                instagramStatus: igStatus,
                instagramError: nil,
                facebookPostId: fbStatus == .published ? "fb_\(i)" : nil,
                facebookStatus: fbStatus,
                facebookError: nil,
                tiktokPostId: tkStatus == .published ? "tk_\(i)" : nil,
                tiktokStatus: tkStatus,
                tiktokError: tkStatus == .failed ? "Rate limit exceeded" : nil,
                instagramLikes: status == .published ? Int.random(in: 120...800) : 0,
                instagramComments: status == .published ? Int.random(in: 5...60) : 0,
                instagramReach: status == .published ? Int.random(in: 800...5000) : 0,
                facebookLikes: status == .published ? Int.random(in: 80...400) : 0,
                facebookComments: status == .published ? Int.random(in: 3...30) : 0,
                facebookReach: status == .published ? Int.random(in: 500...3500) : 0,
                tiktokViews: tkStatus == .published ? Int.random(in: 200...2000) : 0,
                tiktokLikes: tkStatus == .published ? Int.random(in: 20...200) : 0,
                retryCount: status == .failed ? 3 : 0,
                createdAt: date
            ))
        }

        for i in 1...5 {
            let date = calendar.date(byAdding: .day, value: i, to: now)!
            let category = categories[i % categories.count]
            posts.append(Post(
                id: "future-\(i)",
                category: category,
                caption: "",
                hashtags: "",
                imageUrl: nil,
                imagePrompt: nil,
                scheduledFor: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date)!,
                publishedAt: nil,
                status: .pending,
                instagramPostId: nil,
                instagramStatus: .pending,
                instagramError: nil,
                facebookPostId: nil,
                facebookStatus: .pending,
                facebookError: nil,
                tiktokPostId: nil,
                tiktokStatus: .pending,
                tiktokError: nil,
                instagramLikes: 0,
                instagramComments: 0,
                instagramReach: 0,
                facebookLikes: 0,
                facebookComments: 0,
                facebookReach: 0,
                tiktokViews: 0,
                tiktokLikes: 0,
                retryCount: 0,
                createdAt: now
            ))
        }

        return posts.sorted { $0.scheduledFor > $1.scheduledFor }
    }

    static func generateAccounts() -> [SocialAccount] {
        [
            SocialAccount(id: "acc-1", platform: .instagram, accountName: "@rumomaquinas", accountId: "17841...", isActive: true, tokenExpiresAt: Calendar.current.date(byAdding: .day, value: 45, to: Date())),
            SocialAccount(id: "acc-2", platform: .facebook, accountName: "Rumo Máquinas", accountId: "58831...", isActive: true, tokenExpiresAt: nil),
            SocialAccount(id: "acc-3", platform: .tiktok, accountName: "@rumomaquinas", accountId: "", isActive: false, tokenExpiresAt: nil)
        ]
    }

    static func generateCalendar() -> [ContentCalendarEntry] {
        [
            ContentCalendarEntry(id: "cal-1", dayOfWeek: 1, category: .dicaManutencao, subcategory: "Trator", promptTemplate: "Gere uma dica profissional sobre manutenção preventiva de tratores...", imageStyle: "Fotografia profissional de trator agrícola moderno em campo aberto...", isActive: true),
            ContentCalendarEntry(id: "cal-2", dayOfWeek: 2, category: .curiosidadeAgro, subcategory: "Agricultura", promptTemplate: "Gere uma curiosidade surpreendente sobre agricultura brasileira...", imageStyle: "Vista aérea de lavoura de soja verde infinita no cerrado brasileiro...", isActive: true),
            ContentCalendarEntry(id: "cal-3", dayOfWeek: 3, category: .economiaCombustivel, subcategory: "Diesel", promptTemplate: "Gere um post sobre como economizar diesel em máquinas agrícolas...", imageStyle: "Close-up profissional de abastecimento de trator agrícola...", isActive: true),
            ContentCalendarEntry(id: "cal-4", dayOfWeek: 4, category: .gestaoFazenda, subcategory: "Tecnologia", promptTemplate: "Gere um post sobre como tecnologia está transformando a gestão de fazendas...", imageStyle: "Produtor rural brasileiro usando tablet...", isActive: true),
            ContentCalendarEntry(id: "cal-5", dayOfWeek: 5, category: .pecuaria, subcategory: "Gado", promptTemplate: "Gere um post com dica prática para pecuaristas...", imageStyle: "Rebanho de gado nelore em pasto verde...", isActive: true),
            ContentCalendarEntry(id: "cal-6", dayOfWeek: 6, category: .motivacionalAgro, subcategory: "Produtor Rural", promptTemplate: "Gere um post motivacional para produtores rurais brasileiros...", imageStyle: "Silhueta de produtor rural olhando horizonte...", isActive: true),
            ContentCalendarEntry(id: "cal-7", dayOfWeek: 0, category: .appShowcase, subcategory: "Controle de Máquina", promptTemplate: "Gere um post apresentando uma funcionalidade do app Controle de Máquina...", imageStyle: "Mockup de smartphone com app de gestão agrícola...", isActive: true),
        ]
    }

    static func generateMetrics() -> MetricsSummary {
        MetricsSummary(
            instagramReach: 45230,
            instagramReachChange: 23.0,
            instagramLikes: 3450,
            instagramComments: 287,
            facebookReach: 32100,
            facebookReachChange: 15.0,
            facebookLikes: 2100,
            facebookComments: 156,
            tiktokViews: 12500,
            tiktokViewsChange: 45.0,
            tiktokLikes: 890,
            totalPosts: 60,
            publishedPosts: 55,
            failedPosts: 5,
            bestHour: "07:00 - 08:00",
            bestCategory: "Dica Manutenção"
        )
    }

    private static func captionFor(_ category: PostCategory) -> String {
        switch category {
        case .dicaManutencao:
            return "🔧 Você sabia que 70% das quebras de trator poderiam ser evitadas com manutenção preventiva?\n\nSegundo dados da ANFAVEA, o custo de manutenção preventiva é até 5x menor que o reparo corretivo. Confira 3 dicas essenciais:\n\n1️⃣ Verifique o nível de óleo do motor diariamente antes de ligar\n2️⃣ Troque os filtros nos intervalos recomendados pelo fabricante\n3️⃣ Monitore o horímetro para não perder os prazos de revisão\n\n📱 Com o app Controle de Máquina, você recebe alertas automáticos de manutenção e nunca mais perde um prazo!\n\nBaixe grátis: app.controledemaquina.com.br"
        case .curiosidadeAgro:
            return "🌱 Você sabia que o Brasil é o maior produtor mundial de café, soja, laranja e cana-de-açúcar?\n\nSegundo o IBGE, a safra brasileira 2025/2026 bateu recorde com mais de 320 milhões de toneladas de grãos!\n\nIsso é o equivalente a encher mais de 5 milhões de caminhões.\n\nO agro brasileiro alimenta 1 em cada 6 pessoas no mundo. Orgulho de quem vive do campo! 🇧🇷\n\n📱 Gerencie suas máquinas com o app Controle de Máquina"
        case .economiaCombustivel:
            return "⛽ Diesel mais caro? 5 dicas para economizar até 20% de combustível nas suas máquinas!\n\n1️⃣ Mantenha a pressão dos pneus correta\n2️⃣ Evite rotações acima do necessário\n3️⃣ Faça manutenção preventiva dos filtros de ar\n4️⃣ Planeje rotas eficientes na lavoura\n5️⃣ Monitore o consumo real por hora trabalhada\n\n📱 O app Controle de Máquina registra o abastecimento e calcula o consumo real de cada máquina!"
        case .gestaoFazenda:
            return "📊 A tecnologia está revolucionando a gestão de fazendas no Brasil!\n\nHoje, com um smartphone, o produtor rural consegue:\n\n✅ Controlar manutenção de todas as máquinas\n✅ Monitorar custos de operação por hectare\n✅ Receber alertas de revisão automáticos\n✅ Gerar relatórios de produtividade\n\nQuem ainda usa caderninho está perdendo tempo e dinheiro.\n\n📱 Experimente o app Controle de Máquina gratuitamente!"
        case .pecuaria:
            return "🐂 Dica de ouro para pecuaristas: a eficiência no manejo começa pelas máquinas!\n\nTratores e implementos bem mantidos significam:\n- Menos paradas inesperadas durante o manejo\n- Menor custo operacional por cabeça\n- Mais tempo produtivo no campo\n\nUm trator parado na hora errada pode atrasar todo o manejo do rebanho.\n\n📱 Use o Controle de Máquina para manter tudo em dia!"
        case .motivacionalAgro:
            return "🌅 Enquanto a cidade dorme, o produtor rural já está de pé.\n\nÉ nas mãos calejadas de quem planta e cuida que nasce o alimento de milhões. Cada safra é uma batalha vencida. Cada bezerro nascido é mais uma vitória.\n\nO Brasil é grande porque o agro é forte. E o agro é forte porque tem gente como VOCÊ.\n\nValorizamos quem alimenta o Brasil! 💪🇧🇷\n\n📱 Controle de Máquina - feito para quem vive do campo"
        case .appShowcase:
            return "📱 Conheça o Controle de Máquina - o app que está transformando a gestão de máquinas agrícolas!\n\n⚙️ Controle de Abastecimento: registre cada abastecimento e saiba o consumo real\n🔧 Manutenção Preventiva: receba alertas antes do prazo vencer\n⏱ Horímetro Digital: acompanhe as horas trabalhadas de cada máquina\n💰 Custos por Máquina: saiba exatamente quanto custa cada operação\n\n+10.000 produtores já usam!\n\nBaixe grátis: app.controledemaquina.com.br"
        }
    }
}
