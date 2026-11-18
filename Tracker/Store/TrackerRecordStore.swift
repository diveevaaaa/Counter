import CoreData

protocol TrackerRecordStoreDelegate: AnyObject {
    func trackerRecordStoreDidUpdate()
}

@objc(TrackerRecordCoreData)
final class TrackerRecordCoreData: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var date: Date?
    @NSManaged var tracker: TrackerCoreData?
}

extension TrackerRecordCoreData {
    @nonobjc class func fetchRequest() -> NSFetchRequest<TrackerRecordCoreData> {
        NSFetchRequest<TrackerRecordCoreData>(entityName: "TrackerRecordCoreData")
    }
}

final class TrackerRecordStore: NSObject, NSFetchedResultsControllerDelegate {
    weak var delegate: TrackerRecordStoreDelegate?

    private let context: NSManagedObjectContext
    private let trackerStore: TrackerStore
    private let fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData>

    init(trackerStore: TrackerStore) {
        context = PersistentContainer.shared.viewContext
        self.trackerStore = trackerStore
        let request = TrackerRecordCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
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

    func records() -> [TrackerRecord] {
        let request = TrackerRecordCoreData.fetchRequest()
        let objects = (try? context.fetch(request)) ?? []
        return objects.compactMap { object in
            guard let date = object.date, let trackerId = object.tracker?.id else { return nil }
            return TrackerRecord(trackerId: trackerId, date: date)
        }
    }

    func add(trackerId: UUID, on date: Date) {
        guard record(trackerId: trackerId, on: date) == nil,
              let tracker = trackerStore.tracker(id: trackerId) else { return }
        let object = TrackerRecordCoreData(context: context)
        object.id = UUID()
        object.date = date
        object.tracker = tracker
        PersistentContainer.shared.saveIfNeeded()
    }

    func remove(trackerId: UUID, on date: Date) {
        guard let object = record(trackerId: trackerId, on: date) else { return }
        context.delete(object)
        PersistentContainer.shared.saveIfNeeded()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerRecordStoreDidUpdate()
    }

    private func record(trackerId: UUID, on date: Date) -> TrackerRecordCoreData? {
        let request = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "tracker.id == %@", trackerId as NSUUID)
        let objects = (try? context.fetch(request)) ?? []
        return objects.first { object in
            guard let storedDate = object.date else { return false }
            return Calendar.current.isDate(storedDate, inSameDayAs: date)
        }
    }
}
