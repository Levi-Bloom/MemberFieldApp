import Foundation

enum AppConfig {
    /// Supabase project URL — copy from stockman-bellweather-labs `.env.local` (`NEXT_PUBLIC_SUPABASE_URL`).
    static let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"]
        ?? "https://vrbtonpyeaqmuilbckch.supabase.co"

    /// Supabase anon key — copy from `.env.local` (`NEXT_PUBLIC_SUPABASE_ANON_KEY`).
    static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
        ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyYnRvbnB5ZWFxbXVpbGJja2NoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4NTcwNDksImV4cCI6MjA5NjQzMzA0OX0.eTqHoLZAx8ycKjUYXq03vAwNBM4ghtFhNyC3RYms900"

    static let defaultAnnualMembershipFeeCents = 5000

    static var isConfigured: Bool {
        !supabaseURL.contains("your-project") && !supabaseAnonKey.contains("your-anon")
    }
}
