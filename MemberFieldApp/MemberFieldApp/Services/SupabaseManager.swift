import Foundation
import Supabase

@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        guard let url = URL(string: AppConfig.supabaseURL) else {
            fatalError("Invalid Supabase URL in AppConfig")
        }
        client = SupabaseClient(supabaseURL: url, supabaseKey: AppConfig.supabaseAnonKey)
    }
}
