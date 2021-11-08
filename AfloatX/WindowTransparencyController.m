//
//  WindowTransparencyController.m
//  AfloatX
//
//  Created by j on 12/6/19.
//  Copyright © 2019 j. All rights reserved.
//

#import "WindowTransparencyController.h"

@implementation WindowTransparencyController
- (void)setWindowTransparency:(NSSlider *)sender {
    [self.window setAlphaValue:sender.floatValue];
}

- (void)endSheet {
    [self.window endSheet:self.sheetWindow];
}

- (void)endSheetForWindow:(NSWindow *)window {
    [window endSheet:self.sheetWindow];
}

- (void)runSheet {
    self.transparencySlider.floatValue = [self.window alphaValue];
    [self.window beginSheet:self.sheetWindow completionHandler:nil];
}

- (void)runSheetForWindow:(NSWindow *)window {
    self.window = window;
    [self runSheet];
}

- (instancetype)initWithWindow:(NSWindow *)window {
    self.window = window;
    return [self init];
}

- (instancetype)init {
    self = [super init];
    self.sheetWindow = [NSWindow new];
    [self.sheetWindow setFrame:CGRectMake(0, 0, 270, 90) display:YES];
    
    NSTextField *label = [NSTextField labelWithString:@"Transparency:"];
    [label setFrameOrigin:CGPointMake(15, 35)];
    
    self.transparencySlider = [NSSlider sliderWithTarget:self action:@selector(setWindowTransparency:)];
    self.transparencySlider.frame = CGRectMake(15, 8, 205, 25);

    NSButton *endSheetButton = [[NSButton alloc] initWithFrame:CGRectMake(230, 9, 20, 25)];
    endSheetButton.bezelStyle = NSBezelStyleRoundRect;
    endSheetButton.image = [NSImage imageNamed:NSImageNameMenuOnStateTemplate];
    endSheetButton.target = self;
    endSheetButton.action = @selector(endSheet);
    
    [self.sheetWindow.contentView addSubview:label];
    [self.sheetWindow.contentView addSubview:self.transparencySlider];
    [self.sheetWindow.contentView addSubview:endSheetButton];
    return self;
}

+ (instancetype)sharedInstance
{
    static WindowTransparencyController *controller = nil;
    @synchronized(self) {
        if (!controller) {
            controller = [[self alloc] init];
        }
    }
    return controller;
}

@end
