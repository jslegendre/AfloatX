//
//  AfloatX.m
//  AfloatX
//
//  Created by Jeremy Legendre on 10/11/19.
//Copyright © 2019 Jeremy Legendre. All rights reserved.
//

@import AppKit;
#import "AfloatX.h"
#import "ZKSwizzle.h"
#import <objc/runtime.h>
#import <objc/message.h>

NSMenu *AfloatXMenu;
NSMenuItem *AfloatXItem;
NSMenu *AfloatXSubmenu;
NSMenuItem *floatItem;
NSMenuItem *dropItem;
NSMenuItem *resetItem;
NSMenuItem *transparencyItem;
NSMenu *transparencyItemSubMenu;
NSMenuItem *moreTransparentItem;
NSMenuItem *lessTransparentItem;
NSMenuItem *transientItem;
NSArray *afloatXItems;
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
  * Blocks all mouse/keyboard actions. Not really worth implementing IMO, but it's here if you want to
- (void)blockMainWindow {
    objc_msgSend([self windowToModify], sel_getUid("_setDisableInteraction:"), YES);
}

- (void)unblockMainWindow {
    objc_msgSend([self windowToModify], sel_getUid("_setDisableInteraction:"), NO);
}
*/

- (BOOL)isWindowTransient:(NSWindow *)window {
    if ((NSWindowCollectionBehaviorTransient & [window collectionBehavior]) == NSWindowCollectionBehaviorTransient ) {
        return YES;
    }
    return NO;
}

- (void)toggleTransientMainWindow {
    if(![self isWindowTransient:[self windowToModify]]) {
        [[self windowToModify] setCollectionBehavior:
            ([[self windowToModify] collectionBehavior] | NSWindowCollectionBehaviorTransient)];
    } else {
        [[self windowToModify] setCollectionBehavior:
            ([[self windowToModify] collectionBehavior] & ~NSWindowCollectionBehaviorTransient)];
    }
}

- (void)floatMainWindow {
    [[self windowToModify] setLevel:NSFloatingWindowLevel];
}

- (void)dropMainWindow {
    [[self windowToModify] setLevel:kCGBackstopMenuLevel];
}

- (void)resetMainWindow {
    [[self windowToModify] setLevel:NSNormalWindowLevel];
}

- (void)moreTransparentMainWindow {
    CGFloat alphaValue = [[self windowToModify] alphaValue];
    alphaValue -= 0.2;
    [[self windowToModify] setAlphaValue: alphaValue];
}

- (void)lessTransparentMainWindow {
    CGFloat alphaValue = [[self windowToModify] alphaValue];
    alphaValue += 0.2;
    [[self windowToModify] setAlphaValue: alphaValue];
}

+ (void)load {
    AfloatX *plugin = [AfloatX sharedInstance];
    NSUInteger osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    NSLog(@"%@ loaded into %@ on macOS 10.%ld", [self class], [[NSBundle mainBundle] bundleIdentifier], (long)osx_ver);

    menuInjected = NO;
    
    AfloatXMenu = [NSMenu new];
    AfloatXItem = [NSMenuItem new];
    AfloatXItem.title = @"AfloatX";
    AfloatXSubmenu = [NSMenu new];
    AfloatXItem.submenu = AfloatXSubmenu;
    floatItem = [[NSMenuItem alloc] initWithTitle:@"Float Window" action:@selector(floatMainWindow) keyEquivalent:@""];
    [floatItem setTarget:plugin];
    dropItem = [[NSMenuItem alloc] initWithTitle:@"Drop Window" action:@selector(dropMainWindow) keyEquivalent:@""];
    [dropItem setTarget:plugin];
    resetItem = [[NSMenuItem alloc] initWithTitle:@"Reset Window" action:@selector(resetMainWindow) keyEquivalent:@""];
    [resetItem setTarget:plugin];
    transientItem = [[NSMenuItem alloc] initWithTitle:@"Transient Window" action:@selector(toggleTransientMainWindow) keyEquivalent:@""];
    [transientItem setTarget:plugin];
    
    transparencyItem = [NSMenuItem new];
    transparencyItem.title = @"Transparency";
    transparencyItemSubMenu = [NSMenu new];
    transparencyItem.submenu = transparencyItemSubMenu;
    
    NSString *s = [NSString stringWithFormat:@"T%C", 0x001f];
    moreTransparentItem = [[NSMenuItem alloc] initWithTitle:@"More Transparent" action:@selector(moreTransparentMainWindow) keyEquivalent:s];
    [moreTransparentItem setTarget:plugin];
    
    s = [NSString stringWithFormat:@"T%C", 0x001e];
    lessTransparentItem = [[NSMenuItem alloc] initWithTitle:@"Less Transparent" action:@selector(lessTransparentMainWindow) keyEquivalent:s];
    [lessTransparentItem setTarget:plugin];
    [transparencyItemSubMenu setItemArray:@[moreTransparentItem, lessTransparentItem]];

    afloatXItems = [[NSArray alloc] initWithObjects:floatItem, dropItem, transparencyItem, nil];
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
    
    if([window level] != NSNormalWindowLevel) {
        if([window level] == kCGBackstopMenuLevel) {
            afloatXItems = @[floatItem, resetItem, transientItem, transparencyItem];
        } else if([window level] == NSFloatingWindowLevel) {
            afloatXItems = @[resetItem, dropItem, transientItem, transparencyItem];
        }
    } else {
        afloatXItems = @[floatItem, dropItem, transientItem, transparencyItem];
    }

    [AfloatXSubmenu setItemArray:afloatXItems];
    return ZKOrig(CFArrayRef, arg1, arg2);
}
@end
