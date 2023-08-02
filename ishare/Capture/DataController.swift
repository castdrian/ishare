//
//  DataController.swift
//  ishare
//
//  Created by Adrian Castro on 02.08.23.
//

import CoreData
import Foundation

class DataController:  ObservableObject  {
    let container = NSPersistentContainer(name: "Video")

    static var shared = DataController()

    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load \(error.localizedDescription)")
            }
        }
    }

    var moc: NSManagedObjectContext {
        return (container.viewContext)
    }

        func save() {
            if moc.hasChanges {
                do {
                    print("Successfully saved video")
                    try moc.save()
                } catch {
                    print("Error while saving managedObjectContext \(error)")
                }
            }
        }
}
public extension NSManagedObject {

    convenience init(usedContext: NSManagedObjectContext) {
        let name = String(describing: type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: usedContext)!
        self.init(entity: entity, insertInto: usedContext)
    }

}
