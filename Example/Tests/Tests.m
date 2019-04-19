//
//  OCHookingTests.m
//  OCHookingTests
//
//  Created by tripleCC on 04/18/2019.
//  Copyright (c) 2019 tripleCC. All rights reserved.
//

@import XCTest;
@import ObjectiveC;
#import <OCHooking/OCHooking.h>

static unsigned int count = 0;

@interface A : NSObject
- (void)invoke;
@end
@implementation A
+ (void)c_invoke {
    count++;
}

+ (void)hooked_c_invoke:(BOOL)b {}

+ (void)hooked_c_invoke {
    [self hooked_c_invoke];
    count++;
}

- (void)invoke {
    count++;
}

- (void)invoke:(BOOL)l1 :(BOOL)l2 {}

- (void)hooked_invoke:(BOOL)b {}

- (void)hooked_invoke {
    [self hooked_invoke];
    count++;
}

- (void)unknow_hooked_invoke {
    count++;
}
@end

@interface B : A
@end
@implementation B
@end

@interface Tests : XCTestCase {
    A *_a;
    B *_b;
}

@end


static void recoverSwizzle(Class cls, SEL os, SEL ss) {
    Method o = class_getInstanceMethod(cls, os);
    Method s = class_getInstanceMethod(cls, ss);
    method_exchangeImplementations(o, s);
}

@implementation Tests

- (void)setUp
{
    [super setUp];
    _a = [A new];
    _b = [B new];
    count = 0;
}

- (void)testInheritMethod {
    [OCHooking swizzleMethod:@selector(invoke) onClass:[B class] withSwizzledSelector:@selector(hooked_invoke)];
    
    [self addTeardownBlock:^{
        recoverSwizzle([B class], @selector(invoke), @selector(hooked_invoke));
    }];
    
    [_b invoke];
    
    XCTAssertTrue(count == 2);
    
    [_a invoke];
    
    XCTAssertTrue(count == 3);
}

- (void)testHookClassMethodWithBlock {
    SEL sel = [OCHooking swizzledSelectorForSelector:@selector(c_invoke)];
    __block NSInvocation *invocation = [OCHooking swizzleClassMethod:@selector(c_invoke) onClass:[A class] withBlockMethod:[OCHBlockMethod methodWithSelector:sel block:^ {
        count++;
        [invocation invoke];
    }]];

    [self addTeardownBlock:^{
        recoverSwizzle(object_getClass([A class]), @selector(c_invoke), sel);
    }];

    [A c_invoke];

    XCTAssertTrue(count == 2);
}

- (void)testHookInstanceMethodWithBlock {
    SEL sel = [OCHooking swizzledSelectorForSelector:@selector(invoke)];
    __block NSInvocation *invocation = [OCHooking swizzleMethod:@selector(invoke) onClass:[A class] withBlockMethod:[OCHBlockMethod methodWithSelector:sel block:^ {
        count++;
        [invocation invokeWithTarget:_a];
    }]];

    [self addTeardownBlock:^{
        recoverSwizzle([A class], @selector(invoke), sel);
    }];

    [_a invoke];

    XCTAssertTrue(count == 2);
}

- (void)testHookInstanceMethod {
    [OCHooking swizzleMethod:@selector(invoke) onClass:[A class] withSwizzledSelector:@selector(hooked_invoke)];

    [self addTeardownBlock:^{
        recoverSwizzle([A class], @selector(invoke), @selector(hooked_invoke));
    }];

    [_a invoke];

    XCTAssertTrue(count == 2);
}

- (void)testHookClassMethod {
    [OCHooking swizzleClassMethod:@selector(c_invoke) onClass:[A class] withSwizzledSelector:@selector(hooked_c_invoke)];

    [self addTeardownBlock:^{
        recoverSwizzle(object_getClass([A class]), @selector(c_invoke), @selector(hooked_c_invoke));
    }];

    [A c_invoke];

    XCTAssertTrue(count == 2);
}

- (void)testUnknowOriginalMethod {
    SEL sel = NSSelectorFromString(@"unknow_invoke");

    XCTAssertThrows([OCHooking swizzleMethod:sel onClass:[A class] withBlockMethod:[OCHBlockMethod methodWithSelector:[OCHooking swizzledSelectorForSelector:@selector(unknow_hooked_invoke)] block:^ { }]]);

    XCTAssertThrows([OCHooking swizzleClassMethod:sel onClass:[A class] withBlockMethod:[OCHBlockMethod methodWithSelector:[OCHooking swizzledSelectorForSelector:@selector(unknow_hooked_invoke)] block:^ { }]]);

    XCTAssertThrows([OCHooking swizzleMethod:sel onClass:[A class] withSwizzledSelector:@selector(unknow_hooked_invoke)]);

    XCTAssertThrows([OCHooking swizzleClassMethod:sel onClass:[A class] withSwizzledSelector:@selector(hooked_invoke:)]);
}

- (void)testSignatureCompatible {
    XCTAssertThrows([OCHooking swizzleClassMethod:@selector(c_invoke) onClass:[A class] withSwizzledSelector:@selector(hooked_c_invoke:)]);

    XCTAssertThrows([OCHooking swizzleClassMethod:@selector(invoke) onClass:[A class] withSwizzledSelector:@selector(hooked_invoke:)]);

    XCTAssertThrows([OCHooking swizzleMethod:@selector(invoke) onClass:[A class] withBlockMethod:[OCHBlockMethod methodWithSelector:[OCHooking swizzledSelectorForSelector:@selector(invoke)] block:^ BOOL{
        return YES;
    }]]);

    XCTAssertThrows([OCHooking swizzleClassMethod:@selector(c_invoke) onClass:[A class] withBlockMethod:[OCHBlockMethod methodWithSelector:[OCHooking swizzledSelectorForSelector:@selector(c_invoke)] block:^ BOOL{
        return YES;
    }]]);

    XCTAssertThrows([OCHooking swizzleMethod:@selector(invoke) onClass:[A class] withBlockMethod:[OCHBlockMethod methodWithSelector:[OCHooking swizzledSelectorForSelector:@selector(invoke)] block:^ (BOOL b){
    }]]);

    XCTAssertNoThrow([OCHooking swizzleMethod:@selector(invoke::) onClass:[A class] withBlockMethod:[OCHBlockMethod methodWithSelector:[OCHooking swizzledSelectorForSelector:@selector(invoke::)] block:^ (BOOL b){
    }]]);
}
@end

