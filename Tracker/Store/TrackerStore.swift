import CoreData
import UIKit

protocol TrackerStoreDelegate: AnyObject {
    func trackerStoreDidUpdate()
}

@objc(TrackerCoreData)
final class TrackerCoreData: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var emoji: String?
    @NSManaged var colorHex: String?
    @NSManaged var schedule: String?
    @NSManaged var category: TrackerCategoryCoreData?
    @NSManaged var records: NSSet?
}

extension TrackerCoreData {
    @nonobjc class func fetchRequest() -> NSFetchRequest<TrackerCoreData> {
        NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
    }

    func makeTracker() -> Tracker {
        Tracker(
            id: id ?? UUID(),
            name: name ?? "",
            color: UIColor(trackerHex: colorHex ?? "FD4C49"),
            emoji: emoji ?? "",
            schedule: TrackerSchedule(storedValue: schedule ?? "")
        )
    }

    func fill(from tracker: Tracker) {
        id = tracker.id
        name = tracker.name
        emoji = tracker.emoji
        colorHex = tracker.color.trackerHex
        schedule = tracker.schedule.storedValue
    }
}

final class TrackerStore: NSObject, NSFetchedResultsControllerDelegate {
    weak var delegate: TrackerStoreDelegate?

    private let context: NSManagedObjectContext
    private let categoryStore: TrackerCategoryStore
    private let fetchedResultsController: NSFetchedResultsController<TrackerCoreData>

    init(categoryStore: TrackerCategoryStore) {
        context = PersistentContainer.shared.viewContext
        self.categoryStore = categoryStore
        let request = TrackerCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        super.init()
        fetchedResultsController.delegate = self
        try? fetchedResultsController.performFetch()
    }

    func add(_ tracker: Tracker, toCategory title: String) {
        let request = TrackerCoreData.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", tracker.id as NSUUID)
        if let existing = try? context.fetch(request), !existing.isEmpty {
            return
        }
        let object = TrackerCoreData(context: context)
        object.fill(from: tracker)
        object.category = categoryStore.category(titled: title)
        PersistentContainer.shared.saveIfNeeded()
    }

    func tracker(id: UUID) -> TrackerCoreData? {
        let request = TrackerCoreData.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        return try? context.fetch(request).first
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerStoreDidUpdate()
    }
}
