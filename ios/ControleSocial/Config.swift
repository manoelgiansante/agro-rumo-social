// Config.swift - Auto-generated at build time
// Environment variables from Project Settings are injected here
//
// Usage: Config.YOUR_ENV_NAME
// Example: If you set MY_API_KEY in Environment Variables,
//          use Config.MY_API_KEY in your code
//
// SECURITY NOTE:
// - NEVER hardcode SERVICE_ROLE_KEY in client apps
// - Only SUPABASE_URL and SUPABASE_ANON_KEY are safe for client use
// - Secret keys (STRIPE_SECRET_KEY, ANTHROPIC_API_KEY, RESEND_API_KEY)
//   must only be used server-side (backend)

import Foundation

enum Config {
    // --- Client-safe keys (ok to embed in app) ---
    static let SUPABASE_URL = ""
    static let SUPABASE_ANON_KEY = ""
    static let STRIPE_PUBLISHABLE_KEY = ""
    static let GOOGLE_CLIENT_ID = ""
    static let META_APP_ID = ""
    static let TIKTOK_CLIENT_KEY = ""

    // --- Resolved helpers (with fallback to known project) ---
    static var resolvedSupabaseURL: String {
        let v = SUPABASE_URL
        return v.isEmpty ? "https://jxcnfyeemdltdfqtgbcl.supabase.co" : v
    }

    static var resolvedAnonKey: String {
        let v = SUPABASE_ANON_KEY
        return v.isEmpty ? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4Y25meWVlbWRsdGRmcXRnYmNsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1MDQwNTksImV4cCI6MjA4NDA4MDA1OX0.MEqgaUHb0cDVoDrXY6rc1F6YJLxzbpNiks-SFRCg2go" : v
    }
}
