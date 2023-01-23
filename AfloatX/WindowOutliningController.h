//
//  WindowOutliningController.h
//  AfloatX
//
//  Created by j on 1/19/20.
//  Copyright © 2020 j. All rights reserved.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WindowOutliningController : NSObject
@property (strong) NSMenuItem *accentColorItem;
@property (strong) NSMenuItem *whiteItem;
@property (strong) NSMenuItem *blackItem;
@property (strong) NSMenuItem *redItem;
@property (strong) NSMenuItem *greenItem;
@property (strong) NSMenuItem *blueItem;
@property (strong) NSMenuItem *yellowItem;
@property (strong) NSMenuItem *orangeItem;
@property (strong) NSMenuItem *purpleItem;
@property (strong) NSArray *colorItems;
@property (strong) NSMenu *menu;
@end

NS_ASSUME_NONNULL_END
