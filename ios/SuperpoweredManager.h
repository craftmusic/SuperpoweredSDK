//
//  SuperpoweredManager.h
//  RNSuperpowered
//
//  Created by Ivan Caceres on 10/11/19.
//  Copyright © 2019 Facebook. All rights reserved.
//

#ifndef SuperpoweredManager_h
#define SuperpoweredManager_h

#import <Foundation/Foundation.h>

@interface SuperpoweredManager : NSObject
+ (instancetype)createInstance;
+ (instancetype)getInstance;

- (instancetype)init;
- (instancetype)initPrivate;
@end

#endif /* SuperpoweredManager_h */
