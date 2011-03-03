//
//  XGPreferencesController.h
//  xGrab
//
//  Created by Filipe Varela on 07/12/27.
//  Copyright 2007 Filipe Varela. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface XGPreferencesController : NSWindowController
{
    id _delegate;
    IBOutlet id videoSettingsView;
    IBOutlet id softwareUpdateView;
    IBOutlet id registrationView;
    IBOutlet id hotkeysView;
    IBOutlet NSBox *contentView;
    NSSize softwareUpdateViewSize,videoSettingsViewSize,registrationViewSize, hotkeysViewSize;
    NSArray *_compressorList;
}

- (IBAction)videoSettingsClicked:(id)sender;
- (IBAction)softwareUpdateClicked:(id)sender;
- (IBAction)registrationClicked:(id)sender;
- (IBAction)hotkeysClicked:(id)sender;

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (void)resizeWindowToSize:(NSSize)newSize;
- (void)switchToView:(NSView *)aView ofSize:(NSSize)aSize withLabel:(NSString *)label;

- (NSArray *)compressorList;

@end
