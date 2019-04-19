//
//  OCHooking.h
//  OCHooking
//
//  Created by tripleCC on 4/18/19.
//

#import <Foundation/Foundation.h>
#import "OCHBlockMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface OCHooking : NSObject
+ (SEL)swizzledSelectorForSelector:(SEL)selector;

+ (void)swizzleMethod:(SEL)originalSelector onClass:(_Nonnull Class)cls withSwizzledSelector:(SEL)swizzledSelector;
+ (void)swizzleClassMethod:(SEL)originalSelector onClass:(Class)cls withSwizzledSelector:(SEL)swizzledSelector;

+ (NSInvocation *)swizzleMethod:(SEL)originalSelector onClass:(_Nonnull Class)cls withBlockMethod:(OCHBlockMethod * _Nonnull)blockMethod;
+ (NSInvocation *)swizzleClassMethod:(SEL)originalSelector onClass:(Class)cls withBlockMethod:(OCHBlockMethod *)blockMethod;
@end

NS_ASSUME_NONNULL_END
