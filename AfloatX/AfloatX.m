//
//  AfloatX.m
//  AfloatX
//
//  Created by Jeremy Legendre on 10/11/19.
//Copyright © 2019 Jeremy Legendre. All rights reserved.
//

@import AppKit;
@import CoreImage.CIFilter;
#import "AfloatX.h"
#import "WindowTransparencyController.h"
#import "ZKSwizzle.h"
#import <objc/runtime.h>
#import <objc/message.h>

WindowTransparencyController *transparencyController;
NSMenu *AfloatXMenu;
NSMenuItem *AfloatXItem;
NSMenu *AfloatXSubmenu;
NSMenuItem *floatItem;
NSMenuItem *dropItem;
NSMenuItem *transparencyItem;
NSMenuItem *transientItem;
NSMenuItem *stickyItem;
NSMenuItem *invertColorItem;
NSArray *afloatXItems;
CIFilter* colorInvertFilter;
BOOL menuInjected;

@interface AfloatX()

@end

@implementation AfloatX

/**
 * @return the single static instance of the plugin object
 */
+ (instancetype)sharedInstance
{
    static AfloatX *plugin = nil;
    @synchronized(self) {
        if (!plugin) {
            plugin = [[self alloc] init];
        }
    }
    return plugin;
}

- (NSWindow *)windowToModify {
    NSWindow *window = [NSApp mainWindow];
    if(!window)
        window = objc_msgSend(NSApp, sel_getUid("frontWindow"));
    return window;
}

/*
 Convenience methods for setting/removing filters. Will keep the process of setting
 filters streamlined.
 */
- (void)addFilter:(CIFilter *)filter toWindow:(NSWindow *)window {
    NSMutableArray *filters = [[[window.contentView superview] contentFilters] mutableCopy];
    [filters addObject:filter];
    [[window.contentView superview] setContentFilters:[filters copy]];
}

- (void)removeFilter:(CIFilter *)filter fromWindow:(NSWindow *)window {
    NSMutableArray *filters = [[[window.contentView superview] contentFilters] mutableCopy];
    for (CIFilter *f in filters) {
        if([f isEqual:filter])
            [filters removeObject:f];
    }
    [[window.contentView superview] setContentFilters:[filters copy]];
}

- (CGWindowLevel)getCGWindowLevelForWindow:(NSWindow *)window {
    int32_t windowLevel = 0;
    CGSGetWindowLevel(CGSMainConnectionID(), (unsigned int)[window windowNumber], &windowLevel);
    return windowLevel;
}

/*
 Use private Core Graphics API to set window level so the windows' collection
 behavior is not affected. Unlike -[NSWindow setLevel:], CGSSetWindowLevel only
 acts on a single window and not any of its child/attached windows so that must
 be done manually.
*/
- (void)setWindow:(NSWindow *)window toLevel:(CGWindowLevel)level {
    if([window attachedSheet])
        [self setWindow:window.attachedSheet toLevel:level];
    
    for(NSWindow *childWindow in [window childWindows])
        [self setWindow:childWindow toLevel:level];
    
    CGSSetWindowLevel(CGSMainConnectionID(), (unsigned int)([window windowNumber]), level);
}

- (BOOL)window:(NSWindow *)window isLevel:(CGWindowLevel)level {
    CGWindowLevel windowLevel = [self getCGWindowLevelForWindow:window];
    if(windowLevel == level)
        return YES;
    
    return NO;
}

- (void)setMainWindowLevel:(CGWindowLevel)level {
    [self setWindow:[self windowToModify] toLevel:level];
}

 /*
  * Blocks all mouse/keyboard actions. Not really worth implementing IMO, but it's here if you want to
- (void)blockMainWindow {
    objc_msgSend([self windowToModify], sel_getUid("_setDisableInteraction:"), YES);
}

- (void)unblockMainWindow {
    objc_msgSend([self windowToModify], sel_getUid("_setDisableInteraction:"), NO);
}
*/

- (BOOL)isWindowTransient:(NSWindow *)window {
    NSUInteger collectionBehavior = [window collectionBehavior];
    if ((NSWindowCollectionBehaviorMoveToActiveSpace & collectionBehavior) ==
        NSWindowCollectionBehaviorMoveToActiveSpace) {
        return YES;
    }
    return NO;
}

- (BOOL)isWindowSticky:(NSWindow *)window {
    NSUInteger collectionBehavior = [window collectionBehavior];
    if ((NSWindowCollectionBehaviorCanJoinAllSpaces & collectionBehavior) ==
        NSWindowCollectionBehaviorCanJoinAllSpaces) {
        return YES;
    }
    return NO;
}

- (void)toggleTransientMainWindow {
    if(![self isWindowTransient:[self windowToModify]]) {
        [[self windowToModify] setCollectionBehavior:
            ([[self windowToModify] collectionBehavior] | NSWindowCollectionBehaviorMoveToActiveSpace)];
    } else {
        [[self windowToModify] setCollectionBehavior:
            ([[self windowToModify] collectionBehavior] & ~NSWindowCollectionBehaviorMoveToActiveSpace)];
    }
}

- (void)toggleStickyMainWindow {
    if(![self isWindowSticky:[self windowToModify]]) {
        [[self windowToModify] setCollectionBehavior:
            ([[self windowToModify] collectionBehavior] | NSWindowCollectionBehaviorCanJoinAllSpaces)];
    } else {
        [[self windowToModify] setCollectionBehavior:
            ([[self windowToModify] collectionBehavior] & ~NSWindowCollectionBehaviorCanJoinAllSpaces)];
    }
}

- (void)toggleColorInvert {
    NSWindow *window = [self windowToModify];
    [[window.contentView superview] setWantsLayer:YES];
    
    if (![objc_getAssociatedObject(window, "isColorInverted") boolValue]) {
        [self addFilter:colorInvertFilter toWindow:window];
        objc_setAssociatedObject(window, "isColorInverted", [NSNumber numberWithBool:true], OBJC_ASSOCIATION_RETAIN);
    } else {
        [self removeFilter:colorInvertFilter fromWindow:window];
        objc_setAssociatedObject(window, "isColorInverted", [NSNumber numberWithBool:false], OBJC_ASSOCIATION_RETAIN);
    }
}

- (BOOL)isMainWindowFloating {
    return [self window:[self windowToModify] isLevel:kCGFloatingWindowLevel];
}

- (void)toggleFloatMainWindow {
    if([self isMainWindowFloating]) {
        [self setMainWindowLevel:kCGNormalWindowLevel];
    } else {
        [self setMainWindowLevel:kCGFloatingWindowLevel];
    }
}

- (BOOL)isMainWindowDropped {
    return [self window:[self windowToModify] isLevel:kCGBackstopMenuLevel];
}

- (void)toggleDropMainWindow {
    if([self isMainWindowDropped]) {
        [self setMainWindowLevel:kCGNormalWindowLevel];
    } else {
        [self setMainWindowLevel:kCGBackstopMenuLevel];
    }
}

- (void)showTransparencySheet {
    [transparencyController runSheetForWindow:[self windowToModify]];
    if([self isMainWindowFloating]) {
        [self setMainWindowLevel:kCGFloatingWindowLevel];
    }
}

+ (void)load {
    AfloatX *plugin = [AfloatX sharedInstance];
    NSArray *blackList = [[NSArray alloc] initWithObjects:@"com.apple.dock", nil];
    if ([blackList containsObject:NSBundle.mainBundle.bundleIdentifier])
        return;
    
    NSUInteger osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    NSLog(@"%@ loaded into %@ on macOS 10.%ld", [self class], [[NSBundle mainBundle] bundleIdentifier], (long)osx_ver);

    colorInvertFilter = [CIFilter filterWithName:@"CIColorInvert"];
    [colorInvertFilter setDefaults];
    
    menuInjected = NO;
    
    transparencyController = [WindowTransparencyController sharedInstance];
    
    AfloatXMenu = [NSMenu new];
    AfloatXItem = [NSMenuItem new];
    AfloatXItem.title = @"AfloatX";
    AfloatXSubmenu = [NSMenu new];
    AfloatXItem.submenu = AfloatXSubmenu;
    
    floatItem = [[NSMenuItem alloc] initWithTitle:@"Float Window" action:@selector(toggleFloatMainWindow) keyEquivalent:@""];
    [floatItem setTarget:plugin];
    
    dropItem = [[NSMenuItem alloc] initWithTitle:@"Drop Window" action:@selector(toggleDropMainWindow) keyEquivalent:@""];
    [dropItem setTarget:plugin];
    
    transientItem = [[NSMenuItem alloc] initWithTitle:@"Transient Window" action:@selector(toggleTransientMainWindow) keyEquivalent:@""];
    [transientItem setTarget:plugin];
    
    stickyItem = [[NSMenuItem alloc] initWithTitle:@"Sticky Window" action:@selector(toggleStickyMainWindow) keyEquivalent:@""];
    [stickyItem setTarget:plugin];
    
    invertColorItem = [[NSMenuItem alloc] initWithTitle:@"Invert Colors" action:@selector(toggleColorInvert) keyEquivalent:@""];
    [invertColorItem setTarget:plugin];
    
    transparencyItem = [[NSMenuItem alloc] initWithTitle:@"Transparency..." action:@selector(showTransparencySheet) keyEquivalent:@""];
    [transparencyItem setTarget:plugin];

    afloatXItems = [[NSArray alloc] initWithObjects:floatItem,
                                                    dropItem,
                                                    invertColorItem,
                                                    stickyItem,
                                                    transientItem,
                                                    transparencyItem,
                                                    nil];
    [AfloatXSubmenu setItemArray:afloatXItems];
    
    // If the application has a custom dock menu, we will add ourselves to that
    if([[NSApp delegate] respondsToSelector:@selector(applicationDockMenu:)]) {
        AfloatXMenu = [[NSApp delegate] applicationDockMenu:NSApp];
        [AfloatXMenu addItem:[NSMenuItem separatorItem]];
        menuInjected = YES;
    }
    
    [AfloatXMenu addItem:AfloatXItem];
     _ZKSwizzle([AXAppDelegate class], [[NSApp delegate] class]);
}

@end

@implementation AXAppDelegate
- (NSMenu *)applicationDockMenu:(NSApplication *)sender {
    if (menuInjected) {
        [AfloatXMenu removeItem:AfloatXItem];
        AfloatXMenu = ZKOrig(NSMenu*, sender);
        // Only add a separator if last item isn't already a separator
        if (!AfloatXMenu.itemArray.lastObject.isSeparatorItem)
            [AfloatXMenu addItem:[NSMenuItem separatorItem]];
        [AfloatXMenu addItem:AfloatXItem];
    }
    return AfloatXMenu;
}
@end

ZKSwizzleInterface(AXApplication, NSApplication, NSResponder)
@implementation AXApplication
- (CFArrayRef)_flattenMenu:(NSMenu *)arg1 flatList:(NSArray *)arg2 {
    // Make any necessary changes to our menu before it is 'flattened'
    NSWindow *window = [[AfloatX sharedInstance] windowToModify];
    
    if([[AfloatX sharedInstance] isWindowTransient:window]) {
        [transientItem setState:NSControlStateValueOn];
    } else {
        [transientItem setState:NSControlStateValueOff];
    }
    
    if([[AfloatX sharedInstance] isWindowSticky:window]) {
        [stickyItem setState:NSControlStateValueOn];
    } else {
        [stickyItem setState:NSControlStateValueOff];
    }
    
    CGWindowLevel windowLevel = [[AfloatX sharedInstance] getCGWindowLevelForWindow:window];
    if(windowLevel != kCGNormalWindowLevel) {
        if(windowLevel == kCGBackstopMenuLevel) {
            [dropItem setState:NSControlStateValueOn];
            [floatItem setState:NSControlStateValueOff];
        } else if(windowLevel == kCGFloatingWindowLevel) {
            [floatItem setState:NSControlStateValueOn];
            [dropItem setState:NSControlStateValueOff];
        }
    } else {
        [dropItem setState:NSControlStateValueOff];
        [floatItem setState:NSControlStateValueOff];
    }
    
    if ([objc_getAssociatedObject(window, "isColorInverted") boolValue]) {
        [invertColorItem setState:NSControlStateValueOn];
    } else {
        [invertColorItem setState:NSControlStateValueOff];
    }
    
    return ZKOrig(CFArrayRef, arg1, arg2);
}
@end
