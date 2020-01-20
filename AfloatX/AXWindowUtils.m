//
//  AXWindowUtils.m
//  AfloatX
//
//  Created by j on 1/20/20.
//  Copyright © 2020 j. All rights reserved.
//

#import "AXWindowUtils.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation AXWindowUtils

+ (NSWindow *)windowToModify {
    NSWindow *window = [NSApp mainWindow];
    if(!window)
        window = objc_msgSend(NSApp, sel_getUid("frontWindow"));
    return window;
}

/*
 Convenience methods for setting/removing filters. Will keep the process of setting
 filters streamlined.
 */
+ (void)addFilter:(CIFilter *)filter toWindow:(NSWindow *)window {
    NSMutableArray *filters = [[[window.contentView superview] contentFilters] mutableCopy];
    [filters addObject:filter];
    [[window.contentView superview] setContentFilters:[filters copy]];
}

+ (void)removeFilter:(CIFilter *)filter fromWindow:(NSWindow *)window {
    NSMutableArray *filters = [[[window.contentView superview] contentFilters] mutableCopy];
    for (CIFilter *f in filters) {
        if([f isEqual:filter])
            [filters removeObject:f];
    }
    [[window.contentView superview] setContentFilters:[filters copy]];
}

+ (CGWindowLevel)getCGWindowLevelForWindow:(NSWindow *)window {
    int32_t windowLevel = 0;
    CGSGetWindowLevel(CGSMainConnectionID(), (unsigned int)[window windowNumber], &windowLevel);
    return windowLevel;
}

+ (void)getTags:(CGSWindowTag (*)[2])tags forWindow:(NSWindow *)window {
    CGSGetWindowTags(CGSMainConnectionID(), (unsigned int)[window windowNumber], *tags, 32);
}

+ (void)setTags:(CGSWindowTag [2])tags forWindow:(NSWindow *)window {
    CGSSetWindowTags(CGSMainConnectionID(), (unsigned int)[window windowNumber], tags, 32);
}

+ (BOOL)window:(NSWindow *)window hasHighTag:(CGSWindowTag)tag {
    CGSWindowTag tags[2];
    [AXWindowUtils getTags:&tags forWindow:window];
    if ((tags[1] & tag) == tag) {
        return YES;
    }
    return NO;
}

+ (BOOL)window:(NSWindow *)window hasLowTag:(CGSWindowTag)tag {
    CGSWindowTag tags[2];
    [AXWindowUtils getTags:&tags forWindow:window];
    if ((tags[0] & tag) == tag) {
        return YES;
    }
    return NO;
}

+ (void)removeHighTag:(CGSWindowTag)tag fromWindow:(NSWindow *)window {
    CGSWindowTag tags[2] = { 0, tag };
    CGSClearWindowTags(CGSMainConnectionID(), (unsigned int)[window windowNumber], tags, 32);
}

+ (void)removeLowTag:(CGSWindowTag)tag fromWindow:(NSWindow *)window {
    CGSWindowTag tags[2] = { tag, 0 };
    CGSClearWindowTags(CGSMainConnectionID(), (unsigned int)[window windowNumber], tags, 32);
}

+ (void)addHighTag:(CGSWindowTag)tag toWindow:(NSWindow *)window {
    CGSWindowTag tags[2];
    [AXWindowUtils getTags:&tags forWindow:window];
    tags[1] |= tag;
    [AXWindowUtils setTags:tags forWindow:window];
}

+ (void)addLowTag:(CGSWindowTag)tag toWindow:(NSWindow *)window {
    CGSWindowTag tags[2];
    [AXWindowUtils getTags:&tags forWindow:window];
    tags[0] |= tag;
    [AXWindowUtils setTags:tags forWindow:window];
}

/*
 Use private Core Graphics API to set window level so the windows' collection
 behavior is not affected. Unlike -[NSWindow setLevel:], CGSSetWindowLevel only
 acts on a single window and not any of its child/attached windows so that must
 be done manually.
*/
+ (void)setWindow:(NSWindow *)window toLevel:(CGWindowLevel)level {
    if([window attachedSheet])
        [AXWindowUtils setWindow:window.attachedSheet toLevel:level];
    
    for(NSWindow *childWindow in [window childWindows])
        [AXWindowUtils setWindow:childWindow toLevel:level];
    
    CGSSetWindowLevel(CGSMainConnectionID(), (unsigned int)([window windowNumber]), level);
}

+ (BOOL)window:(NSWindow *)window isLevel:(CGWindowLevel)level {
    CGWindowLevel windowLevel = [AXWindowUtils getCGWindowLevelForWindow:window];
    if(windowLevel == level)
        return YES;
    
    return NO;
}

+ (void)setMainWindowLevel:(CGWindowLevel)level {
    [AXWindowUtils setWindow:[AXWindowUtils windowToModify] toLevel:level];
}

@end
