//
//  XGPreferencesToolbar.m
//  xGrab
//
//  Created by Filipe Varela on 08/01/22.
//  Copyright 2008 Filipe Varela. All rights reserved.
//

#import "XGPreferencesToolbar.h"

@implementation XGPreferencesController (ToolbarCategory)

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier: (NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];

    if ( [itemIdentifier isEqualToString:@"Video Settings"] ) {
        [item setLabel:@"Video Settings"];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"capture-settings"]];
        [item setTarget:self];
        [item setAction:@selector(videoSettingsClicked:)];
    } else if ( [itemIdentifier isEqualToString:@"Hotkeys Settings"] ) {
        [item setLabel:@"Hotkeys Settings"];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"hotkeys"]];
        [item setTarget:self];
        [item setAction:@selector(hotkeysClicked:)];
    } else if ( [itemIdentifier isEqualToString:@"Software Update"] ) {
        [item setLabel:@"Software Update"];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"software-update"]];
        [item setTarget:self];
        [item setAction:@selector(softwareUpdateClicked:)];
    } else if ( [itemIdentifier isEqualToString:@"Registration"] ) {
        [item setLabel:@"Registration"];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"registration"]];
        [item setTarget:self];
        [item setAction:@selector(registrationClicked:)];
    }

    return [item autorelease];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects: @"Video Settings", @"Hotkeys Settings", @"Software Update", @"Registration", nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects: @"Video Settings", @"Hotkeys Settings", @"Software Update", @"Registration",nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects: @"Video Settings", @"Hotkeys Settings", @"Software Update", @"Registration",nil];
}

- (void)setupToolbar
{
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"prefsToolbar"];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:YES];
	[[self window] setToolbar:[toolbar autorelease]];
}
	
@end

