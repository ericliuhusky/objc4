// MARK: 类型

public typealias id = objc_object
public typealias Class = objc_class
public typealias SEL = String
public typealias IMP = Any
public typealias Method = method_t

public class objc_object {
    var isa: Class?
}

public class objc_class: objc_object {
    var superclass: Class?
    var name: String!
    var methods = [Method]()
    var isMetaClass = false
}

public class method_t {
    let name: SEL
    let types: String
    var imp: IMP
    
    init(name: SEL, types: String, imp: IMP) {
        self.name = name
        self.types = types
        self.imp = imp
    }
}


// MARK: 全局变量存储类字典

var gdb_objc_realized_classes = [String: Class]()


// MARK: - 创建类

public func objc_allocateClassPair(_ superclass: Class?, _ name: String) -> Class? {
    guard gdb_objc_realized_classes[name] == nil else { return nil }
    
    let cls = Class()
    let meta = Class()
    
    cls.name = name
    meta.name = name
    
    meta.isMetaClass = true
    
    cls.isa = meta
    meta.isa = superclass?.isa?.isa
    cls.superclass = superclass
    meta.superclass = superclass?.isa
    
    return cls
}

public func objc_registerClassPair(_ cls: Class) {
    gdb_objc_realized_classes[cls.name] = cls
}

public func objc_getClass(_ aClassName: String) -> Class? {
    gdb_objc_realized_classes[aClassName]
}


// MARK: - 为类添加方法

@discardableResult
public func class_addMethod(_ cls: Class?, _ name: SEL, _ imp: IMP, _ types: String?) -> Bool {
    addMethod(cls, name, imp, types ?? "", false) == nil
}

@discardableResult
public func class_replaceMethod(_ cls: Class?, _ name: SEL, _ imp: IMP, _ types: String?) -> IMP? {
    addMethod(cls, name, imp, types ?? "", true)
}

func addMethod(_ cls: Class?, _ name: SEL, _ imp: IMP, _ types: String, _ replace: Bool) -> IMP? {
    if let method = getMethodNoSuper(cls, name) {
        if !replace {
            return method.imp
        } else {
            let old = method.imp
            method.imp = imp
            return old
        }
    }
    
    cls?.methods.append(Method(name: name, types: types, imp: imp))
    return nil
}

func getMethodNoSuper(_ cls: Class?, _ sel: SEL) -> Method? {
    cls?.methods.first { method in
        method.name == sel
    }
}


// MARK: - 发送消息调用方法

@discardableResult
public func objc_msgSend(_ self: id?, _ op: SEL, _ args: id...) -> id? {
    guard let self = self else { return nil }
    
    if let imp = lookUpImpOrForward(op, self.isa) {
        switch args.count {
        case 0:
            if let imp = imp as? (id) -> id {
                return imp(self)
            }
            (imp as? (id) -> Void)?(self)
        case 1:
            if let imp = imp as? (id, id) -> id {
                return imp(self, args[0])
            }
            (imp as? (id, id) -> Void)?(self, args[0])
        case 2:
            if let imp = imp as? (id, id, id) -> id {
                return imp(self, args[0], args[1])
            }
            (imp as? (id, id, id) -> Void)?(self, args[0], args[1])
        default:
            break
        }
    }
    return nil
}

func lookUpImpOrForward(_ sel: SEL, _ cls: Class?) -> IMP? {
    var imp = lookUpImp(sel, cls)
    if imp == nil {
        imp = resolveMethod(sel, cls)
    }
    if imp == nil {
        func messageForward() {
            
        }
        messageForward()
    }
    return imp
}

func lookUpImp(_ sel: SEL, _ cls: Class?) -> IMP? {
    getMethod(cls, sel)?.imp
}

func getMethod(_ cls: Class?, _ sel: SEL) -> Method? {
    var cls = cls
    while cls != nil {
        if let method = getMethodNoSuper(cls, sel) {
            return method
        }
        cls = cls?.superclass
    }
    return nil
}

func resolveMethod(_ sel: SEL, _ cls: Class?) -> IMP? {
    guard let cls = cls else { return nil }
    
    func resolveInstanceMethod(_ sel: SEL, _ cls: Class) -> IMP? {
        let resolve_sel = sel_registerName("resolveInstanceMethod")
        return lookUpImp(resolve_sel, cls.isa)
    }
    
    func resolveClassMethod(_ sel: SEL, _ cls: Class) -> IMP? {
        let resolve_sel = sel_registerName("resolveClassMethod")
        return lookUpImp(resolve_sel, cls)
    }
    
    if !cls.isMetaClass {
        return resolveInstanceMethod(sel, cls)
    } else {
        if let imp = resolveClassMethod(sel, cls) {
            return imp
        }
        return resolveInstanceMethod(sel, cls)
    }
}


// MARK: -

public func class_getClassMethod(_ cls: Class?, _ sel: SEL) -> Method? {
    class_getInstanceMethod(cls?.isa, sel)
}

public func class_getInstanceMethod(_ cls: Class?, _ sel: SEL) -> Method? {
    getMethod(cls, sel)
}

public func class_getName(_ cls: Class?) -> String {
    cls?.name ?? "nil"
}

public func class_getSuperclass(_ cls: Class?) -> Class? {
    cls?.superclass
}

public func class_isMetaClass(_ cls: Class?) -> Bool {
    cls?.isMetaClass ?? false
}

public func object_getClass(_ obj: id?) -> Class? {
    obj?.isa
}

public func object_getClassName(_ obj: id?) -> String {
    obj?.isa?.name ?? "nil"
}

public func sel_registerName(_ name: String) -> SEL {
    name
}

public func method_getImplementation(_ m: Method) -> IMP {
    m.imp
}

public func method_getTypeEncoding(_ m: Method) -> String {
    m.types
}

public func method_exchangeImplementations(_ m1: Method, _ m2: Method) {
    let imp1 = m1.imp
    let imp2 = m2.imp
    
    m1.imp = imp2
    m2.imp = imp1
}
