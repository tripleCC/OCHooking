//
//  OCHooking.m
//  OCHooking
//
//  Created by tripleCC on 4/18/19.
//
#import <objc/runtime.h>
#import "OCHBlockMethod.h"
#import "OCHooking.h"

static void OCHSwizzleInstanceMethod(Class cls, Method originalMethod, Method swizzledMethod) {
    IMP swizzledImp = method_getImplementation(swizzledMethod);
    const char *swizzledTypes = method_getTypeEncoding(swizzledMethod);
    SEL originalSelector = method_getName(originalMethod);
    SEL swizzledSelector = method_getName(swizzledMethod);
    
    BOOL didAddMethod = class_addMethod(cls, originalSelector, swizzledImp, swizzledTypes);
    if (didAddMethod) {
        class_replaceMethod(cls, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@implementation OCHooking
+ (SEL)swizzledSelectorForSelector:(SEL)selector {
    return NSSelectorFromString([NSString stringWithFormat:@"_ochhooking_swizzle_%x_%@", arc4random(), NSStringFromSelector(selector)]);
}

+ (void)swizzleMethod:(SEL)originalSelector onClass:(Class)cls withSwizzledSelector:(SEL)swizzledSelector {
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    
    NSAssert(swizzledMethod, @"Swizzled method should not be nil");
    
    if (originalMethod && swizzledMethod) {
        const char *originalEncoding = method_getTypeEncoding(originalMethod);
        const char *swizzledEncoding = method_getTypeEncoding(swizzledMethod);
        NSAssert(!strcmp(originalEncoding, swizzledEncoding), @"Swizzled method type encoding should equal to original method type encoding");
    }
    
    OCHSwizzleInstanceMethod(cls, originalMethod, swizzledMethod);
}

+ (void)swizzleClassMethod:(SEL)originalSelector onClass:(Class)cls withSwizzledSelector:(SEL)swizzledSelector {
    Class metaCls = object_getClass(cls);
    [self swizzleMethod:originalSelector onClass:metaCls withSwizzledSelector:swizzledSelector];
}

+ (NSInvocation *)swizzleMethod:(SEL)originalSelector onClass:(Class)cls withBlockMethod:(OCHBlockMethod *)blockMethod {
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    NSMethodSignature *originalSignature;
    
    if (originalMethod) {
        const char *originalEncoding = method_getTypeEncoding(originalMethod);
        originalSignature = [NSMethodSignature signatureWithObjCTypes:originalEncoding];
        NSAssert([blockMethod isCompatibleWithSignature:originalSignature], @"Swizzled method type encoding should equal to original method type encoding");
    }
    
    class_addMethod(cls, blockMethod.selector, blockMethod.imp, blockMethod.types);
    Method swizzledMethod = class_getInstanceMethod(cls, blockMethod.selector);
    
    OCHSwizzleInstanceMethod(cls, originalMethod, swizzledMethod);
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:originalSignature];
    invocation.selector = blockMethod.selector;
    
    return invocation;
}

+ (NSInvocation *)swizzleClassMethod:(SEL)originalSelector onClass:(Class)cls withBlockMethod:(OCHBlockMethod *)blockMethod {
    Class metaCls = object_getClass(cls);
    NSInvocation *invocation = [self swizzleMethod:originalSelector onClass:metaCls withBlockMethod:blockMethod];
    invocation.target = cls;
    
    return invocation;
}
@end