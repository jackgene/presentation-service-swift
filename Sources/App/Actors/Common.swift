class HashableInstance<T>: Hashable {
    let instance: T
    
    init(_ instance: T) {
        self.instance = instance
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(instance as AnyObject))
    }
    
    public static func == (l: HashableInstance, r: HashableInstance) -> Bool {
        l.instance as AnyObject === r.instance as AnyObject
    }
}
