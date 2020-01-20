//
//  AXWindowUtils.h
//  AfloatX
//
//  Created by j on 1/20/20.
//  Copyright © 2020 j. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreImage.CIFilter;

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    CGSTagExposeFade    = 0x0002,   // Fade out when Expose activates.
    CGSTagNoShadow        = 0x0008,   // No window shadow.
    CGSTagTransparent   = 0x0200,   // Transparent to mouse clicks.
    CGSTagOpaque        = 0x400,    // Opaque to mouse clicks.
    CGSTagSticky        = 0x0800,   // Appears on all workspaces.
} CGSWindowTag;

typedef int CGSConnectionID;
CG_EXTERN CGSConnectionID CGSMainConnectionID(void);
CG_EXTERN CGError CGSGetWindowLevel(CGSConnectionID cid, CGWindowID wid, CGWindowLevel *outLevel);
CG_EXTERN CGError CGSSetWindowLevel(CGSConnectionID cid, CGWindowID wid, CGWindowLevel level);
CG_EXTERN CGError CGSGetWindowTags(CGSConnectionID cid, CGWindowID wid, CGSWindowTag *tags, int thirtyTwo);
CG_EXTERN CGError CGSSetWindowTags(CGSConnectionID cid, CGWindowID wid, CGSWindowTag *tags, int thirtyTwo);
CG_EXTERN CGError CGSClearWindowTags(CGSConnectionID cid, CGWindowID wid, CGSWindowTag *tags, int thirtyTwo);

@interface AXWindowUtils : NSObject
+ (NSWindow *)windowToModify;
+ (void)addFilter:(CIFilter *)filter toWindow:(NSWindow *)window;
+ (void)removeFilter:(CIFilter *)filter fromWindow:(NSWindow *)window;
+ (CGWindowLevel)getCGWindowLevelForWindow:(NSWindow *)window;
+ (void)getTags:(CGSWindowTag (*)[2])tags forWindow:(NSWindow *)window;
+ (void)setTags:(CGSWindowTag [_Nullable 2])tags forWindow:(NSWindow *)window;
+ (BOOL)window:(NSWindow *)window hasHighTag:(CGSWindowTag)tag;
+ (BOOL)window:(NSWindow *)window hasLowTag:(CGSWindowTag)tag;
+ (void)removeHighTag:(CGSWindowTag)tag fromWindow:(NSWindow *)window;
+ (void)removeLowTag:(CGSWindowTag)tag fromWindow:(NSWindow *)window;
+ (void)addHighTag:(CGSWindowTag)tag toWindow:(NSWindow *)window;
+ (void)addLowTag:(CGSWindowTag)tag toWindow:(NSWindow *)window;
+ (void)setWindow:(NSWindow *)window toLevel:(CGWindowLevel)level;
+ (BOOL)window:(NSWindow *)window isLevel:(CGWindowLevel)level;
+ (void)setMainWindowLevel:(CGWindowLevel)level;
@end

NS_ASSUME_NONNULL_END
