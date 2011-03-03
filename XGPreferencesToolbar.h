//
//  XGPreferencesToolbar.h
//  xGrab
//
//  Created by Filipe Varela on 08/01/22.
//  Copyright 2008 Filipe Varela. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XGPreferencesController.h"

@interface XGPreferencesController (ToolbarCategory)

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
- (void)setupToolbar;

@end
