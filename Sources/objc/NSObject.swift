func alloc(_ self: id) -> id {
    let obj = id()
    obj.isa = self as? Class
    return obj
}

func `init`(_ self: id) -> id {
    self
}

public struct NSObjectCreator {
    public static func create() {
        let NSObject = objc_allocateClassPair(nil, "NSObject")!
        objc_registerClassPair(NSObject)
        class_addMethod(object_getClass(NSObject), sel_registerName("alloc"), alloc, nil)
        class_addMethod(NSObject, sel_registerName("init"), `init`, nil)
    }
}
