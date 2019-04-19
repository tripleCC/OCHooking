//
//  NSRunLoop+OCHBlock.m
//  OCHooking
//
//  Created by tripleCC on 4/18/19.
//
#import <objc/runtime.h>
#import "OCHBlockMethod.h"

// Block internals.
typedef NS_OPTIONS(int, OCHBlockFlags) {
    OCHBlockFlagsHasCopyDisposeHelpers = (1 << 25),
    OCHBlockFlagsHasSignature          = (1 << 30)
};
typedef struct och_block {
    __unused Class isa;
    OCHBlockFlags flags;
    __unused int reserved;
    void (__unused *invoke)(struct och_block *block, ...);
    struct {
        unsigned long int reserved;
        unsigned long int size;
        // requires OCHBlockFlagsHasCopyDisposeHelpers
        void (*copy)(void *dst, const void *src);
        void (*dispose)(const void *);
        // requires OCHBlockFlagsHasSignature
        const char *signature;
        const char *layout;
    } *descriptor;
    // imported variables
} *OCHBlockRef;

static char *OCHSignatureForBlock(id block) {
    OCHBlockRef layout = (__bridge OCHBlockRef)(block);
    
    if (!(layout->flags & OCHBlockFlagsHasSignature)) {
        return nil;
    }
    
    void *desc = layout->descriptor;
    desc += 2 * sizeof(unsigned long int);
    
    if (layout->flags & OCHBlockFlagsHasCopyDisposeHelpers) {
        desc += 2 * sizeof(void *);
    }
    
    char *objcTypes = (*(char **)desc);
    return objcTypes;
}

static BOOL OCHIsCompatibleBlockSignature(NSMethodSignature *blockSignature, NSMethodSignature *methodSignature) {
    NSCParameterAssert(blockSignature);
    NSCParameterAssert(methodSignature);
    
    if ([blockSignature isEqual:methodSignature]) {
        return YES;
    }
    
    if (blockSignature.numberOfArguments >= methodSignature.numberOfArguments ||
        blockSignature.methodReturnType[0] != methodSignature.methodReturnType[0]) {
        return NO;
    }
    
    BOOL compatibleSignature = YES;
    
    for (int idx = 2; idx < blockSignature.numberOfArguments; idx++) {
        const char *methodArgument = [methodSignature getArgumentTypeAtIndex:idx];
        const char *blockArgument = [blockSignature getArgumentTypeAtIndex:idx - 1];
        if (!methodArgument || !blockArgument || methodArgument[0] != blockArgument[0]) {
            compatibleSignature = NO;
            break;
        }
    }
    
    return compatibleSignature;
}

@implementation OCHBlockMethod {
    id _block;
    const char *_types;
    SEL _selector;
    IMP _imp;
}

+ (instancetype)methodWithSelector:(SEL)selector block:(id)block {
    return [[self alloc] initWithBlock:block selector:selector];
}

- (instancetype)initWithBlock:(id)block selector:(SEL)selector {
    if (self = [super init]) {
        _block = [block copy];
        _types = OCHSignatureForBlock(_block);
        _imp = imp_implementationWithBlock(_block);
        _selector = selector;
    }
    
    return self;
}

- (BOOL)isCompatibleWithSignature:(NSMethodSignature *)signature {
    NSMethodSignature *blockSignature = [NSMethodSignature signatureWithObjCTypes:_types];
    
    return OCHIsCompatibleBlockSignature(blockSignature, signature);
}

- (const char *)types {
    return _types;
}

- (SEL)selector {
    return _selector;
}

- (IMP)imp {
    return _imp;
}
@end
