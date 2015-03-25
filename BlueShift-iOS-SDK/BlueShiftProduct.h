//
//  BlueShiftProduct.h
//  BlueShift-iOS-SDK
//
//  Created by Arjun K P on 05/03/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlueShiftProduct : NSObject

@property NSString *sku;
@property NSInteger quantity;
@property float price;

- (NSDictionary *)toDictionary;
+ (NSMutableArray *)productsDictionaryMutableArrayForProductsArray:(NSArray *)productsArray;

@end
