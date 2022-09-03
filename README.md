# objc4

swift模拟objc Runtime实现原理

## 方法调用

```swift
import objc

NSObjectCreator.create()

func classMethod(_ self: id) {
    print("classMethod")
}

func instanceMethod(_ self: id) {
    print("instanceMethod")
}

let A = objc_allocateClassPair(objc_getClass("NSObject"), "A")!
objc_registerClassPair(A)
class_addMethod(object_getClass(A), sel_registerName("classMethod"), classMethod, nil)
class_addMethod(A, sel_registerName("instanceMethod"), instanceMethod, nil)

// [A classMethod];
objc_msgSend(
    objc_getClass("A"),
    sel_registerName("classMethod")
)
// [[[A alloc] init] instanceMethod]
objc_msgSend(
    objc_msgSend(
        objc_msgSend(
            objc_getClass("A"),
            sel_registerName("alloc")
        ),
        sel_registerName("init")
    ),
    sel_registerName("instanceMethod")
)
```

## 方法交换

```swift
func swizzleInstanceMethod(_ oldCls: Class, _ oldSel: SEL, _ newCls: Class, _ newSel: SEL) {
    guard let oldMethod = class_getInstanceMethod(oldCls, oldSel) else { return }
    guard let newMethod = class_getInstanceMethod(newCls, newSel) else { return }
    
    if class_addMethod(oldCls, oldSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)) {
        class_replaceMethod(newCls, newSel, method_getImplementation(oldMethod), method_getTypeEncoding(oldMethod))
    } else {
        method_exchangeImplementations(oldMethod, newMethod)
    }
}

func swizzleClassMethod(_ oldCls: Class, _ oldSel: SEL, _ newCls: Class, _ newSel: SEL) {
    guard let oldMethod = class_getClassMethod(oldCls, oldSel) else { return }
    guard let newMethod = class_getClassMethod(newCls, newSel) else { return }
    
    if class_addMethod(object_getClass(oldCls), oldSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)) {
        class_replaceMethod(object_getClass(newCls), newSel, method_getImplementation(oldMethod), method_getTypeEncoding(oldMethod))
    } else {
        method_exchangeImplementations(oldMethod, newMethod)
    }
}

func swizzledMethod(_ self: id) {
    print("swizzled")
}

let B = objc_allocateClassPair(objc_getClass("NSObject"), "B")!
objc_registerClassPair(B)
class_addMethod(B, sel_registerName("swizzledMethod"), swizzledMethod, nil)
class_addMethod(object_getClass(B), sel_registerName("swizzledMethod"), swizzledMethod, nil)

swizzleInstanceMethod(A, sel_registerName("instanceMethod"), B, sel_registerName("swizzledMethod"))
swizzleClassMethod(A, sel_registerName("classMethod"), B, sel_registerName("swizzledMethod"))

objc_msgSend(
    objc_getClass("A"),
    sel_registerName("classMethod")
)
objc_msgSend(
    objc_msgSend(
        objc_msgSend(
            objc_getClass("A"),
            sel_registerName("alloc")
        ),
        sel_registerName("init")
    ),
    sel_registerName("instanceMethod")
)
```

## SPM

```swift
let package = Package(
    name: "temp",
    dependencies: [
        .package(path: "../objc4")
    ],
    targets: [
        .executableTarget(
            name: "temp",
            dependencies: [
                .product(name: "objc", package: "objc4")
            ]
        )
    ]
)
```
