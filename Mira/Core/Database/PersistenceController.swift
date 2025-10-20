import CoreData
import os

final class PersistenceController {
    static let shared = PersistenceController()

    private static let logger = Logger(subsystem: "com.mira8.app", category: "Persistence")

    let container: NSPersistentContainer
    let backgroundContext: NSManagedObjectContext

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Mira8")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // Enable lightweight migration to handle model changes (e.g., removed attributes)
        if let description = container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }

        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                Self.logger.fault("Failed to load persistent store \(description.type, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        backgroundContext = container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        backgroundContext.automaticallyMergesChangesFromParent = true
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }

    func save(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }

        try context.save()
    }
}
