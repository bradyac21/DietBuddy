import SwiftUI
import SwiftData

@main
struct MyApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([WeightEntry.self, Food.self, Meal.self, MealItem.self, Goal.self,
                             SavedMeal.self, SavedMealItem.self])
        let configuration = ModelConfiguration(schema: schema)

        do {
            container = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            #if DEBUG
            // Development convenience: the schema is still evolving and has no migration plan yet,
            // so an incompatible on-disk store would otherwise crash on launch. Wipe it and retry.
            print("⚠️ ModelContainer creation failed (\(error)). Resetting the local store for DEBUG.")
            Self.destroyStore(at: configuration.url)
            do {
                container = try ModelContainer(for: schema, configurations: configuration)
            } catch {
                fatalError("Failed to recreate the model container after reset: \(error)")
            }
            #else
            fatalError("Failed to create the model container: \(error)")
            #endif
        }

        #if DEBUG
        SampleData.populateIfEmpty(container.mainContext)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(container)
    }

    #if DEBUG
    /// Removes the SQLite store and its sidecar files so a fresh, empty store can be created.
    private static func destroyStore(at url: URL) {
        let fileManager = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            let path = url.path + suffix
            try? fileManager.removeItem(atPath: path)
        }
    }
    #endif
}
