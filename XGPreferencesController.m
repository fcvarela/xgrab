//
//  XGPreferencesController.m
//  xGrab
//
//  Created by Filipe Varela on 07/12/27.
//  Copyright 2007 Filipe Varela. All rights reserved.
//

#import "XGPreferencesController.h"
#import "XGPreferencesToolbar.h"

// get compressors
#import "XGCompressor.h"

@implementation XGPreferencesController

- (id)init
{
	self = [super initWithWindowNibName: @"Preferences"];
    _compressorList = [XGCompressor availableCompressors];
	return self;
}

- (void)awakeFromNib
{
    [self setupToolbar];
	[[self window] center];
    
    // store original view sizes... otherwise they'll scale down until no animation occurs
    videoSettingsViewSize = [videoSettingsView frame].size;
    softwareUpdateViewSize = [softwareUpdateView frame].size;
    registrationViewSize = [registrationView frame].size;
    hotkeysViewSize = [hotkeysView frame].size;
    
    [self switchToView: videoSettingsView ofSize: videoSettingsViewSize withLabel:@"Video Settings"];
}

- (void)switchToView:(NSView *)aView ofSize:(NSSize)aSize withLabel:(NSString *)label
{
    // reset content
    [contentView setContentView: nil];
    
    // resize to localSize
    [self resizeWindowToSize: aSize];
    
    // set new contents
    [contentView setContentView: aView];
    
    [[[self window] toolbar] setSelectedItemIdentifier: label];
}

- (IBAction)videoSettingsClicked:(id)sender
{
    [self switchToView: videoSettingsView ofSize: videoSettingsViewSize withLabel:@"Video Settings"];
}

- (IBAction)softwareUpdateClicked:(id)sender
{
    [self switchToView: softwareUpdateView ofSize: softwareUpdateViewSize withLabel:@"Software Update"];
}

- (IBAction)registrationClicked:(id)sender
{
    [self switchToView: registrationView ofSize: registrationViewSize withLabel: @"Registration"];
}

- (IBAction)hotkeysClicked:(id)sender
{
    [self switchToView: hotkeysView ofSize: hotkeysViewSize withLabel: @"Hotkeys Settings"];
}

- (void)resizeWindowToSize:(NSSize)newSize
{	
	NSRect aFrame;
    float newHeight = newSize.height;
	int toolbarHeight = 0;
	
	// CALCULAR ALTURA DA TOOLBAR
	NSToolbar *toolbar = [[self window] toolbar];
	if(toolbar && [toolbar isVisible]){
		NSRect windowFrame = [NSWindow contentRectForFrameRect:[[self window] frame] styleMask:[[self window] styleMask]];
		toolbarHeight = NSHeight(windowFrame) - NSHeight([[[self window] contentView] frame]);
	}
	
	// CALCULAR NOVA FRAME
    aFrame = [NSWindow contentRectForFrameRect:[[self window] frame] styleMask:[[self window] styleMask]];
    
    aFrame.origin.y += aFrame.size.height;
    aFrame.origin.y -= newHeight + toolbarHeight;
    aFrame.size.height = newHeight + toolbarHeight;
	
	[contentView setFrame: NSMakeRect(
		abs(aFrame.size.width/2)-abs(newSize.width/2),[contentView frame].origin.y,newSize.width,[contentView frame].size.height)
	];
	
	aFrame = [NSWindow frameRectForContentRect:aFrame styleMask:[[self window] styleMask]];
	
    [[self window] setFrame:aFrame display:YES animate:YES];
}

- (id)delegate
{
    return _delegate;
}

- (void)setDelegate:(id)aDelegate
{
    if (_delegate)
        [_delegate release];
        
    _delegate = aDelegate;
}

- (NSArray *)compressorList
{
    return _compressorList;
}

@end
