//
//  NSApplication+Private.h
//  AfloatX
//
//  Created by Jeremy on 11/7/21.
//  Copyright © 2021 j. All rights reserved.
//

#ifndef NSApplication_Private_h
#define NSApplication_Private_h

#import <AppKit/AppKit.h>

@interface NSApplication (Private)
- (CFArrayRef)_flattenMenu:(NSMenu *)menu flatList:(id)list;
- (CFArrayRef)_flattenMenu:(NSMenu *)menu flatList:(id)list extraUpdateFlags:(uint32_t)flags;
@end

#endif /* NSApplication_Private_h */
