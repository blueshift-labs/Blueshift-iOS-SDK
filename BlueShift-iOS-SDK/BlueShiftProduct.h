//
//  BlueShiftProduct.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlueShiftProduct : NSObject

@property NSString *sku;
@property NSInteger quantity;
@property float price;

- (NSDictionary *)toDictionary;
+ (NSMutableArray *)productsDictionaryMutableArrayForProductsArray:(NSArray *)productsArray;

@end
