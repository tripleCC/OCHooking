//
//  OCHookingTests.m
//  OCHookingTests
//
//  Created by tripleCC on 04/18/2019.
//  Copyright (c) 2019 tripleCC. All rights reserved.
//

@import XCTest;
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
@end

@interface Tests : XCTestCase {
    A *_a;
}

@end

@implementation Tests

- (void)setUp
{
    [super setUp];
    _a = [A new];
    count = 0;
}


- (void)testHookClassMethodWithBlock {
    void (^hook)(void) = ^{
        SEL sel = [OCHooking swizzledSelectorForSelector:@selector(c_invoke)];
        __block NSInvocation *invocation = [OCHooking swizzleClassMethod:@selector(c_invoke) onClass:[A class] withBlockMethod:[OCHBlockMethod methodWithSelector:sel block:^ {
            count++;
            [invocation invoke];
        }]];
    };
    [self addTeardownBlock:hook];
    hook();
    [A c_invoke];
    
    XCTAssertTrue(count == 2);
}

- (void)testHookInstanceMethodWithBlock {
    void (^hook)(void) = ^{
        SEL sel = [OCHooking swizzledSelectorForSelector:@selector(invoke)];
        __block NSInvocation *invocation = [OCHooking swizzleMethod:@selector(invoke) onClass:[A class] withBlockMethod:[OCHBlockMethod methodWithSelector:sel block:^ {
            count++;
            [invocation invokeWithTarget:_a];
        }]];
    };
    [self addTeardownBlock:hook];
    hook();
    [_a invoke];
    
    XCTAssertTrue(count == 2);
}

- (void)testHookInstanceMethod {
    void (^hook)(void) = ^{
        [OCHooking swizzleMethod:@selector(invoke) onClass:[A class] withSwizzledSelector:@selector(hooked_invoke)];
    };
    [self addTeardownBlock:hook];
    hook();
    [_a invoke];
    
    XCTAssertTrue(count == 2);
}

- (void)testHookClassMethod {
    void (^hook)(void) = ^{
        [OCHooking swizzleClassMethod:@selector(c_invoke) onClass:[A class] withSwizzledSelector:@selector(hooked_c_invoke)];
    };
    [self addTeardownBlock:hook];
    hook();
    [A c_invoke];
    
    XCTAssertTrue(count == 2);
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

