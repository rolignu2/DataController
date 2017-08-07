
class DataController : NSObject {


    var Context: NSManagedObjectContext

    var Model   : String? 

    var Ext     : String?

    var ErrFlag : Bool = false 

    var Entity  : String = ""

    var ErrorQueue : Array = [String]() 


    init( model : String = "" , ext : String = "momd" ){
        super.init()
        self.SetNewContext(model : model , ext : ext )
    }


    func SetNewContext(model : String = "" , ext : String = "momd" ) -> Bool {

        self.Model = model 
        self.Ext   = ext 

        if self.Model != "" {

                //This resource is the same name as your xcdatamodeld contained in your project
                guard let modelURL = Bundle.main.url(forResource: self.Model , withExtension: self.Ext ) else {
                    fatalError("Error loading model from bundle")
                    return false 
                }
                // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
                guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
                    fatalError("Error initializing mom from: \(modelURL)")
                    return false 
                }
    
                let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
    
                Context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
                Context.persistentStoreCoordinator = psc
    
                let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
                queue.async {
                    guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
                        fatalError("Unable to resolve document directory")
                        return false 
                    }
                    let storeURL = docURL.appendingPathComponent("DataModel.sqlite")
                    do {
                        try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
                        //The callback block is expected to complete the User Interface and therefore should be presented back on the main queue so that the user interface does not need to be concerned with which queue this call is coming from.
                        DispatchQueue.main.sync(execute: completionClosure)
                    } catch {
                        fatalError("Error migrating store: \(error)")
                        return false 
                }
            }
        }

        return true 

    }

    func SetContext() -> Bool {
        
        let appDelegate = UIApplication.shared().delegate as! AppDelegate
        self.Context = appDelegate.persistentContainer.viewContext

        return true 
    }


    func getContext() -> NSManagedObjectContext {
         return self.Context
    }


    func SetEntity(entity : String ) {
         self.Entity = entity 
    }

    func IsErrInit() ->  Bool  { return  self.ErrFlag }


    
    func InsertData ( data  : NSDictionary  , entity : String  = "" ) -> Bool {
    
        if entity != "" {
            self.Entity = entity 
        }


        let ent     =  NSEntityDescription.entity(forEntityName: self.Entity , in: self.Context )
        let transc  = NSManagedObject(entity: ent!, insertInto: context)

        for (key, value) in data  {
            transc.setValue(value , forKey: key)
        }

        do {
            try self.Context.save()
            return true 
        } catch let error as NSError  {
            return false 
        } catch {
            return false 
        }

        return false 

    }


    func CountData () -> int {
        let count = self.GetData()
        return count 
    }


    func GetData () {

        //CODIGO A REVISAR YA QUE NO HACE NINGUNA TRANSFORMACION DE LA DATA EN EL OBJECT 
        let fetchRequest: NSFetchRequest<Transcription> = Transcription.fetchRequest()

        do {

            //go get the results
            let searchResults = try getContext().fetch(fetchRequest)
 
            //I like to check the size of the returned results!
            print ("num of results = \(searchResults.count)")
            
            //You need to convert to NSManagedObject to use 'for' loops
            for trans in searchResults as [NSManagedObject] {
                //get the Key Value pairs (although there may be a better way to do that...
                print("\(trans.value(forKey: "audioFileUrlString"))")
            }

        } catch {
            print("Error with request: \(error)")
        }

    }
    

    private func SetError( Merror : String  ){
         self.ErrorQueue.append(Merror)
    }

    public func GetErrors() -> Array {
        return self.ErrorQueue 
    }

    public func CountErrors() -> int {
        return self.ErrorQueue.count 
    }


}
