//
//  NSWindow+AfloatX.m
//  AfloatX
//
//  Created by Jeremy on 10/23/20.
//  Copyright © 2020 j. All rights reserved.
//

#import "NSWindow+AfloatX.h"
#import <objc/runtime.h>
#import <objc/message.h>

typedef int CGSConnectionID;
CG_EXTERN CGSConnectionID CGSMainConnectionID(void);
CG_EXTERN CGError CGSGetWindowLevel(CGSConnectionID cid, CGWindowID wid, CGWindowLevel *outLevel);
CG_EXTERN CGError CGSSetWindowLevel(CGSConnectionID cid, CGWindowID wid, CGWindowLevel level);
CG_EXTERN CGError CGSGetWindowTags(CGSConnectionID cid, CGWindowID wid, CGSWindowTag *tags, int thirtyTwo);
CG_EXTERN CGError CGSSetWindowTags(CGSConnectionID cid, CGWindowID wid, CGSWindowTag *tags, int thirtyTwo);
CG_EXTERN CGError CGSClearWindowTags(CGSConnectionID cid, CGWindowID wid, CGSWindowTag *tags, int thirtyTwo);

@interface NSApplication (Private)
- (NSWindow *)frontWindow;
@end

@implementation NSWindow (AfloatX)

+ (NSWindow *)topWindow {
    NSWindow *window = [NSApp mainWindow];
    if(!window)
        window = [NSApp frontWindow];//((NSWindow* (*)(id, SEL))objc_msgSend)(NSApp, sel_getUid("frontWindow"));
    return window;
}

+ (void)setTopWindowCGWindowLevel:(CGWindowLevel)level {
    NSWindow *topWindow = [NSWindow topWindow];
    if(!topWindow)
        return;
    
    [topWindow setCGWindowLevel:level];
}

- (void)addFilter:(CIFilter *)filter {
    NSMutableArray *filters = [[[self.contentView superview] contentFilters] mutableCopy];
    [filters addObject:filter];
    [[self.contentView superview] setContentFilters:[filters copy]];
}

- (void)removeFilter:(CIFilter *)filter {
    NSMutableArray *filters = [[[self.contentView superview] contentFilters] mutableCopy];
    for (CIFilter *f in filters) {
        if([f isEqual:filter])
            [filters removeObject:f];
    }
    [[self.contentView superview] setContentFilters:[filters copy]];
}

- (CGWindowLevel)getCGWindowLevel {
    int32_t windowLevel = 0;
    CGSGetWindowLevel(CGSMainConnectionID(), (unsigned int)[self windowNumber], &windowLevel);
    return windowLevel;
}

- (void)getTags:(CGSWindowTag (*)[2])tags {
    CGSGetWindowTags(CGSMainConnectionID(), (unsigned int)[self windowNumber], *tags, 32);
}

- (void)setTags:(CGSWindowTag [_Nullable 2])tags {
    CGSSetWindowTags(CGSMainConnectionID(), (unsigned int)[self windowNumber], tags, 32);
}

- (BOOL)hasHighTag:(CGSWindowTag)tag {
    CGSWindowTag tags[2];
    [self getTags:&tags];
    if ((tags[1] & tag) == tag) {
        return YES;
    }
    return NO;
}

- (BOOL)hasLowTag:(CGSWindowTag)tag {
    CGSWindowTag tags[2];
    [self getTags:&tags];
    if ((tags[0] & tag) == tag) {
        return YES;
    }
    return NO;
}

- (void)removeHighTag:(CGSWindowTag)tag {
    CGSWindowTag tags[2] = { 0, tag };
    CGSClearWindowTags(CGSMainConnectionID(), (unsigned int)[self windowNumber], tags, 32);
}

- (void)removeLowTag:(CGSWindowTag)tag {
    CGSWindowTag tags[2] = { tag, 0 };
    CGSClearWindowTags(CGSMainConnectionID(), (unsigned int)[self windowNumber], tags, 32);
}

- (void)addHighTag:(CGSWindowTag)tag {
    CGSWindowTag tags[2];
    [self getTags:&tags];
    tags[1] |= tag;
    [self setTags:tags];
}

- (void)addLowTag:(CGSWindowTag)tag {
    CGSWindowTag tags[2];
    [self getTags:&tags];
    tags[0] |= tag;
    [self setTags:tags];
}

/*
 Use private Core Graphics API to set window level so the windows' collection
 behavior is not affected. Unlike -[NSWindow setLevel:], CGSSetWindowLevel only
 acts on a single window and not any of its child/attached windows so that must
 be done manually.
*/
- (void)setCGWindowLevel:(CGWindowLevel)level {
    if([self attachedSheet])
        [self.attachedSheet setCGWindowLevel:level];
    
    for(NSWindow *childWindow in [self childWindows])
        [childWindow setCGWindowLevel:level];
    
    CGSSetWindowLevel(CGSMainConnectionID(), (unsigned int)([self windowNumber]), level);
}

- (BOOL)isAtCGWindowLevel:(CGWindowLevel)level {
    CGWindowLevel windowLevel = [self getCGWindowLevel];
    if(windowLevel == level)
        return YES;
    
    return NO;
}

@end
