//
//  WindowOutliningController.m
//  AfloatX
//
//  Created by j on 1/19/20.
//  Copyright © 2020 j. All rights reserved.
//

#import "WindowOutliningController.h"
#import "AXWindowUtils.h"

@interface WindowOutliningController ()
@property CGColorRef CGColorWhite;
@property CGColorRef CGColorBlack;
@property CGColorRef CGColorRed;
@property CGColorRef CGColorGreen;
@property CGColorRef CGColorBlue;
@property CGColorRef CGColorYellow;
@property CGColorRef CGColorOrange;
@property CGColorRef CGColorPurple;
@property (assign) NSMenuItem *lastColorItem;
@end

@implementation WindowOutliningController

- (NSView *)themeFrameToModify {
    return [[[AXWindowUtils windowToModify] contentView] superview];
}

- (CALayer *)themeFrameLayer {
    NSView *themeFrame = [self themeFrameToModify];
    themeFrame.wantsLayer = YES;
    return themeFrame.layer;
}

- (void)toggleColor:(CGColorRef)color forItem:(NSMenuItem *)item {
    CALayer *layer = [self themeFrameLayer];
    if(item.state == NSControlStateValueOn) {
        layer.borderWidth = 0.0f;
        item.state = NSControlStateValueOff;
    } else {
        layer.borderWidth = 1.35;
        layer.borderColor = color;
        item.state = NSControlStateValueOn;
    }
    
    if(self.lastColorItem)
        self.lastColorItem.state = NSControlStateValueOff;
    
    self.lastColorItem = item;
}

- (void)toggleWhiteColor:(NSMenuItem *)sender {
    [self toggleColor:self.CGColorWhite forItem:sender];
}

- (void)toggleBlackColor:(NSMenuItem *)sender {
    [self toggleColor:self.CGColorBlack forItem:sender];
}

- (void)toggleRedColor:(NSMenuItem *)sender {
    [self toggleColor:self.CGColorRed forItem:sender];
}

- (void)toggleGreenColor:(NSMenuItem *)sender {
    [self toggleColor:self.CGColorGreen forItem:sender];
}

- (void)toggleBlueColor:(NSMenuItem *)sender {
    [self toggleColor:self.CGColorBlue forItem:sender];
}

- (void)toggleYellowColor:(NSMenuItem *)sender {
    [self toggleColor:self.CGColorYellow forItem:sender];
}

- (void)toggleOrangeColor:(NSMenuItem *)sender {
    [self toggleColor:self.CGColorOrange forItem:sender];
}

- (void)togglePurpleColor:(NSMenuItem *)sender {
    [self toggleColor:self.CGColorPurple forItem:sender];
}

- (instancetype)init {
    self = [super init];
    if(self) {
        self.CGColorWhite = CGColorGetConstantColor(kCGColorWhite);
        self.CGColorBlack = CGColorGetConstantColor(kCGColorBlack);
        self.CGColorRed = [[NSColor systemRedColor] CGColor];
        self.CGColorGreen = [[NSColor systemGreenColor] CGColor];
        self.CGColorBlue = [[NSColor systemBlueColor] CGColor];
        self.CGColorYellow = [[NSColor systemYellowColor] CGColor];
        self.CGColorOrange = [[NSColor systemOrangeColor] CGColor];
        self.CGColorPurple = [[NSColor systemPurpleColor] CGColor];
        
        self.whiteItem = [[NSMenuItem alloc] initWithTitle:@"White" action:@selector(toggleWhiteColor:) keyEquivalent:@""];
        [self.whiteItem setTarget:self];
        
        self.blackItem = [[NSMenuItem alloc] initWithTitle:@"Black" action:@selector(toggleBlackColor:) keyEquivalent:@""];
        [self.blackItem setTarget:self];
        
        self.redItem = [[NSMenuItem alloc] initWithTitle:@"Red" action:@selector(toggleRedColor:) keyEquivalent:@""];
        [self.redItem setTarget:self];
        
        self.greenItem = [[NSMenuItem alloc] initWithTitle:@"Green" action:@selector(toggleGreenColor:) keyEquivalent:@""];
        [self.greenItem setTarget:self];
        
        self.blueItem = [[NSMenuItem alloc] initWithTitle:@"Blue" action:@selector(toggleBlueColor:) keyEquivalent:@""];
        [self.blueItem setTarget:self];
        
        self.yellowItem = [[NSMenuItem alloc] initWithTitle:@"Yellow" action:@selector(toggleYellowColor:) keyEquivalent:@""];
        [self.yellowItem setTarget:self];
        
        self.orangeItem = [[NSMenuItem alloc] initWithTitle:@"Orange" action:@selector(toggleOrangeColor:) keyEquivalent:@""];
        [self.orangeItem setTarget:self];
        
        self.purpleItem = [[NSMenuItem alloc] initWithTitle:@"Purple" action:@selector(togglePurpleColor:) keyEquivalent:@""];
        [self.purpleItem setTarget:self];
        
        self.colorItems = [[NSArray alloc] initWithObjects: self.whiteItem,
                                                            self.blackItem,
                                                            self.redItem,
                                                            self.greenItem,
                                                            self.blueItem,
                                                            self.yellowItem,
                                                            self.orangeItem,
                                                            self.purpleItem,
                                                            nil];
    }
    return self;
}
@end
