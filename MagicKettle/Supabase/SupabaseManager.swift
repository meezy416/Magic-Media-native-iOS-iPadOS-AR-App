//
//  SupabaseManager.swift
//  MagicKettle
//

import Foundation
import Supabase

final class SupabaseManager {

    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        guard
            let plistURL = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: plistURL),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
            let urlString = plist["SupabaseURL"],
            let supabaseURL = URL(string: urlString),
            let anonKey = plist["SupabaseAnonKey"]
        else {
            fatalError("MagicKettle/Secrets.plist is missing or malformed. Copy Secrets.example.plist to Secrets.plist and fill in your Supabase project's URL and anon key.")
        }

        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: anonKey)
    }

    var isSignedIn: Bool {
        get async {
            (try? await client.auth.session) != nil
        }
    }
}
