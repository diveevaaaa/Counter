import CoreData

protocol TrackerCategoryStoreDelegate: AnyObject {
    func trackerCategoryStoreDidUpdate()
}

@objc(TrackerCategoryCoreData)
final class TrackerCategoryCoreData: NSManagedObject {
    @NSManaged var title: String?
    @NSManaged var trackers: NSSet?
}

extension TrackerCategoryCoreData {
    @nonobjc class func fetchRequest() -> NSFetchRequest<TrackerCategoryCoreData> {
        NSFetchRequest<TrackerCategoryCoreData>(entityName: "TrackerCategoryCoreData")
    }

    var trackerObjects: [TrackerCoreData] {
        let set = trackers as? Set<TrackerCoreData> ?? []
        return set.sorted { lhs, rhs in
            let left = lhs.name ?? ""
            let right = rhs.name ?? ""
            if left == right {
                return (lhs.id?.uuidString ?? "") < (rhs.id?.uuidString ?? "")
            }
            return left.localizedStandardCompare(right) == .orderedAscending
        }
    }
}

final class TrackerCategoryStore: NSObject, NSFetchedResultsControllerDelegate {
    weak var delegate: TrackerCategoryStoreDelegate?

    private let context: NSManagedObjectContext
    private let fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData>

    override init() {
        context = PersistentContainer.shared.viewContext
        let request = TrackerCategoryCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
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

    func categories() -> [TrackerCategory] {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        let objects = (try? context.fetch(request)) ?? []
        return objects.map { object in
            TrackerCategory(
                title: object.title ?? "",
                trackers: object.trackerObjects.map { $0.makeTracker() }
            )
        }
    }

    func category(titled title: String) -> TrackerCategoryCoreData {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "title ==[c] %@", title)
        if let existing = try? context.fetch(request).first {
            return existing
        }
        let created = TrackerCategoryCoreData(context: context)
        created.title = title
        return created
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerCategoryStoreDidUpdate()
    }
}
