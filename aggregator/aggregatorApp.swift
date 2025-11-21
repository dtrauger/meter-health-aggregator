//
//  aggregatorApp.swift
//  aggregator
//
//  Created by Derek Trauger on 10/28/25.
//

import SwiftUI
import SwiftData

@main
struct aggregatorApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            UserGroup.self,
            HealthDataEntry.self,
        ])
        
        do {
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Print detailed error information
            print("❌ Failed to create ModelContainer: \(error)")
            
            // If this is a migration error, try to provide more context
            if let swiftDataError = error as? SwiftDataError {
                print("SwiftData Error Details: \(swiftDataError)")
            }
            
            // During development, you might want to reset the store on migration failures
            // CAUTION: This deletes all existing data!
            #if DEBUG
            print("⚠️ Attempting to clear and recreate store (DEBUG only)")
            
            // Get the default store URL and try to delete it
            let url = ModelConfiguration(schema: schema).url
            print("Store URL: \(url)")
            try? FileManager.default.removeItem(at: url)
            
            // Also remove associated files
            let directoryURL = url.deletingLastPathComponent()
            if let files = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) {
                for file in files {
                    if file.lastPathComponent.starts(with: url.lastPathComponent) {
                        print("Removing: \(file)")
                        try? FileManager.default.removeItem(at: file)
                    }
                }
            }
            
            // Try again with fresh store
            do {
                let newConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                let container = try ModelContainer(for: schema, configurations: [newConfiguration])
                print("✅ Successfully created fresh ModelContainer")
                return container
            } catch {
                print("❌ Still failed after cleanup: \(error)")
            }
            #endif
            
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
