//
//  AfloatX.h
//  AfloatX
//
//  Created by Jeremy Legendre on 10/11/19.
//Copyright © 2019 Jeremy Legendre. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AfloatX : NSObject

+ (instancetype)sharedInstance;
- (NSWindow *)windowToModify;
@end

@interface AXAppDelegate : NSObject <NSApplicationDelegate>
@end

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
