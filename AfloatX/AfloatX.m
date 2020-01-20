//
//  AfloatX.m
//  AfloatX
//
//  Created by Jeremy Legendre on 10/11/19.
//Copyright © 2019 Jeremy Legendre. All rights reserved.
//

@import AppKit;
#import "AfloatX.h"
#import "AXWindowUtils.h"
#import "WindowTransparencyController.h"
#import "WindowOutliningController.h"
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
NSMenuItem *clickPassthroughItem;
NSMenuItem *windowOutlineItem;
NSMenu *windowOutlineSubmenu;
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

- (BOOL)isMainWindowFloating {
    return [AXWindowUtils window:[AXWindowUtils windowToModify] isLevel:kCGFloatingWindowLevel];
}

- (BOOL)isMainWindowDropped {
    return [AXWindowUtils window:[AXWindowUtils windowToModify] isLevel:kCGBackstopMenuLevel];
}

- (void)toggleTransientMainWindow {
    if(![self isWindowTransient:[AXWindowUtils windowToModify]]) {
        [[AXWindowUtils windowToModify] setCollectionBehavior:
            ([[AXWindowUtils windowToModify] collectionBehavior] | NSWindowCollectionBehaviorMoveToActiveSpace)];
    } else {
        [[AXWindowUtils windowToModify] setCollectionBehavior:
            ([[AXWindowUtils windowToModify] collectionBehavior] & ~NSWindowCollectionBehaviorMoveToActiveSpace)];
    }
}

- (void)toggleStickyMainWindow {
    if(![self isWindowSticky:[AXWindowUtils windowToModify]]) {
        [[AXWindowUtils windowToModify] setCollectionBehavior:
            ([[AXWindowUtils windowToModify] collectionBehavior] | NSWindowCollectionBehaviorCanJoinAllSpaces)];
    } else {
        [[AXWindowUtils windowToModify] setCollectionBehavior:
            ([[AXWindowUtils windowToModify] collectionBehavior] & ~NSWindowCollectionBehaviorCanJoinAllSpaces)];
    }
}

- (void)toggleColorInvert {
    NSWindow *window = [AXWindowUtils windowToModify];
    [[window.contentView superview] setWantsLayer:YES];
    
    if (![objc_getAssociatedObject(window, "isColorInverted") boolValue]) {
        [AXWindowUtils addFilter:colorInvertFilter toWindow:window];
        objc_setAssociatedObject(window, "isColorInverted", [NSNumber numberWithBool:true], OBJC_ASSOCIATION_RETAIN);
    } else {
        [AXWindowUtils removeFilter:colorInvertFilter fromWindow:window];
        objc_setAssociatedObject(window, "isColorInverted", [NSNumber numberWithBool:false], OBJC_ASSOCIATION_RETAIN);
    }
}

- (void)toggleEventPassthrough {
    NSWindow *window = [AXWindowUtils windowToModify];
    if([AXWindowUtils window:window hasLowTag:CGSTagTransparent]) {
        [AXWindowUtils removeLowTag:CGSTagTransparent fromWindow:window];
    } else {
        [AXWindowUtils addLowTag:CGSTagTransparent toWindow:window];
    }
}

- (void)toggleFloatMainWindow {
    if([self isMainWindowFloating]) {
        [AXWindowUtils setMainWindowLevel:kCGNormalWindowLevel];
    } else {
        [AXWindowUtils setMainWindowLevel:kCGFloatingWindowLevel];
    }
}

- (void)toggleDropMainWindow {
    if([self isMainWindowDropped]) {
        [AXWindowUtils setMainWindowLevel:kCGNormalWindowLevel];
    } else {
        [AXWindowUtils setMainWindowLevel:kCGBackstopMenuLevel];
    }
}

- (void)showTransparencySheet {
    [transparencyController runSheetForWindow:[AXWindowUtils windowToModify]];
    if([self isMainWindowFloating]) {
        [AXWindowUtils setMainWindowLevel:kCGFloatingWindowLevel];
    }
}

+ (void)load {
    AfloatX *plugin = [AfloatX sharedInstance];
    NSArray *blackList = [[NSArray alloc] initWithObjects:@"com.apple.dock", @"com.vmware.vmware-vmx", @"com.apple.loginwindow", nil];
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
    
    windowOutlineItem = [NSMenuItem new];
    windowOutlineItem.title = @"Outline Window";
    windowOutlineSubmenu = [NSMenu new];
    windowOutlineItem.submenu = windowOutlineSubmenu;
    
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
    
    clickPassthroughItem = [[NSMenuItem alloc] initWithTitle:@"Click-Through Window" action:@selector(toggleEventPassthrough) keyEquivalent:@""];
    [clickPassthroughItem setTarget:plugin];

    transparencyItem = [[NSMenuItem alloc] initWithTitle:@"Transparency..." action:@selector(showTransparencySheet) keyEquivalent:@""];
    [transparencyItem setTarget:plugin];

    afloatXItems = [[NSArray alloc] initWithObjects:floatItem,
                                                    dropItem,
                                                    invertColorItem,
                                                    stickyItem,
                                                    transientItem,
                                                    clickPassthroughItem,
                                                    windowOutlineItem,
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
    NSWindow *window = [AXWindowUtils windowToModify];
    
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
    
    CGWindowLevel windowLevel = [AXWindowUtils getCGWindowLevelForWindow:window];
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
    
    if([AXWindowUtils window:window hasLowTag:CGSTagTransparent]) {
        [clickPassthroughItem setState:NSControlStateValueOn];
    } else {
        [clickPassthroughItem setState:NSControlStateValueOff];
    }
    
    /* Create a new WindowOutliningController per window */
    if (!objc_getAssociatedObject(window, "outlineController")) {
        WindowOutliningController *outlineController = [WindowOutliningController new];
        windowOutlineSubmenu.itemArray = [outlineController colorItems];
        objc_setAssociatedObject(window, "outlineController", outlineController, OBJC_ASSOCIATION_RETAIN);
    } else {
        WindowOutliningController *outlineController = objc_getAssociatedObject(window, "outlineController");
        windowOutlineSubmenu.itemArray = [outlineController colorItems];
    }
    
    if ([objc_getAssociatedObject(window, "isColorInverted") boolValue]) {
        [invertColorItem setState:NSControlStateValueOn];
    } else {
        [invertColorItem setState:NSControlStateValueOff];
    }
    
    return ZKOrig(CFArrayRef, arg1, arg2);
}
@end
