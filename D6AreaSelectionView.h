//
//  D6AreaSelectionView.h
//  xGrab
//
//  Created by Filipe Varela on 08/02/04.
//  Copyright 2008 Filipe Varela. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface D6AreaSelectionView : NSView
{
    NSRect selectionRect;
    BOOL cornerDragged; 
    BOOL contentDragged;
    //delegate
    id _delegate;
}

- (id)initWithFrame:(NSRect)frame andSelection:(NSRect)selection;
- (void)drawRect:(NSRect)rect;
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseUp:(NSEvent *)theEvent;
- (void)mouseDragged:(NSEvent *)theEvent;

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (NSRect)selectionRect;

@end
