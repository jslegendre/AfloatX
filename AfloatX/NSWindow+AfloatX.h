//
//  NSWindow+AfloatX.h
//  AfloatX
//
//  Created by Jeremy on 10/23/20.
//  Copyright © 2020 j. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <CoreImage/CIFilter.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    CGSTagExposeFade    = 0x0002,   // Fade out when Expose activates.
    CGSTagNoShadow        = 0x0008,   // No window shadow.
    CGSTagTransparent   = 0x0200,   // Transparent to mouse clicks.
    CGSTagOpaque        = 0x400,    // Opaque to mouse clicks.
    CGSTagSticky        = 0x0800,   // Appears on all workspaces.
} CGSWindowTag;

@interface NSWindow (AfloatX)

+ (NSWindow *)topWindow;
+ (void)setTopWindowCGWindowLevel:(CGWindowLevel)level;
- (void)addFilter:(CIFilter *)filter;
- (void)removeFilter:(CIFilter *)filter;
- (CGWindowLevel)getCGWindowLevel;
- (void)getTags:(CGSWindowTag (*)[2])tags;
- (void)setTags:(CGSWindowTag [_Nullable 2])tags;
- (BOOL)hasHighTag:(CGSWindowTag)tag;
- (BOOL)hasLowTag:(CGSWindowTag)tag;
- (void)removeHighTag:(CGSWindowTag)tag;
- (void)removeLowTag:(CGSWindowTag)tag;
- (void)addHighTag:(CGSWindowTag)tag;
- (void)addLowTag:(CGSWindowTag)tag;
- (void)setCGWindowLevel:(CGWindowLevel)level;
- (BOOL)isAtCGWindowLevel:(CGWindowLevel)level;

@end

NS_ASSUME_NONNULL_END
