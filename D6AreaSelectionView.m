//
//  D6AreaSelectionView.m
//  xGrab
//
//  Created by Filipe Varela on 08/02/04.
//  Copyright 2008 Filipe Varela. All rights reserved.
//

#import "D6AreaSelectionView.h"

@implementation D6AreaSelectionView

- (id)initWithFrame:(NSRect)frame andSelection:(NSRect)selection
{
    self = [super initWithFrame:frame];
    if (self) {
        if (selection.size.width == 0 || selection.size.height == 0)
            selectionRect = frame;
        else
            selectionRect = selection;
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
    NSColor *myColor;
    
    // basically we need to draw a nsbezierpath (dashed) with the rect
    myColor = [NSColor colorWithCalibratedRed:0.0f green:0.0f blue:0.0f alpha:0.2f];
    [myColor set];
    [NSBezierPath fillRect: selectionRect];
    
    [NSBezierPath setDefaultLineWidth: 1.0f];
    
    myColor = [NSColor colorWithCalibratedRed:0.0f green:0.0f blue:0.0f alpha:0.6f];
    [myColor set];
    [NSBezierPath strokeRect: selectionRect];

    // now draw a circle over the lower left point
    NSPoint thePoint = NSMakePoint(selectionRect.origin.x + selectionRect.size.width, selectionRect.origin.y);
    myColor = [NSColor colorWithCalibratedRed:0.0f green:0.0f blue:0.0f alpha:0.4f];
    [myColor set];
    [[NSBezierPath bezierPathWithOvalInRect: NSMakeRect(thePoint.x-8, thePoint.y-8, 16, 16)] fill];
    
    // and another at the content selection center
    NSPoint centerPoint = NSMakePoint(selectionRect.origin.x + selectionRect.size.width / 2.0, selectionRect.origin.y + selectionRect.size.height / 2.0);
    [[NSBezierPath bezierPathWithOvalInRect: NSMakeRect(centerPoint.x-8, centerPoint.y-8, 16, 16)] fill];
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont fontWithName:@"Helvetica" size: 40], NSFontAttributeName,
        [NSColor darkGrayColor], NSForegroundColorAttributeName,
        [NSNumber numberWithFloat: -2.0f], NSStrokeWidthAttributeName,
        [NSColor whiteColor], NSStrokeColorAttributeName,
        nil];
        
    NSAttributedString * attributedString = [[NSAttributedString alloc] initWithString:
        @"Drag centerpoint to position selection\nDrag lower-right corner to adjust size\n Double-click centerpoint when done"
        attributes: attributes];
    
    [attributedString drawInRect:NSMakeRect(
    [[self window] frame].size.width/2 - 350,
    [[self window] frame].size.height-250,
    [[self window] frame].size.width,200)];
    [attributedString release];
    
    NSDictionary *attributes2 = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont fontWithName:@"Helvetica" size: 40], NSFontAttributeName,
        [NSColor darkGrayColor], NSForegroundColorAttributeName,
        [NSNumber numberWithFloat: -2.0f], NSStrokeWidthAttributeName,
        [NSColor whiteColor], NSStrokeColorAttributeName,
        nil];
    
    NSAttributedString * attributedString2 = [[NSAttributedString alloc] initWithString:
        [NSString stringWithFormat:@"Selected width: %d height: %d", (unsigned)selectionRect.size.width, (unsigned)selectionRect.size.height]
        attributes: attributes2];
        
    [attributedString2 drawInRect:NSMakeRect(
    [[self window] frame].size.width/2 - 300,
    [[self window] frame].size.height-650,
    [[self window] frame].size.width,200)];
    [attributedString2 release];

}

- (void)mouseEntered:(NSEvent *)theEvent
{
	[[self window] setAcceptsMouseMovedEvents:YES];
	[[self window] makeFirstResponder:self];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	[[self window] setAcceptsMouseMovedEvents:NO];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    // get point from event
    NSPoint pt = [self convertPoint: [theEvent locationInWindow] fromView: nil];
	
	// was the point inside the acceptable threshold for lowerleft? cornerDragged = YES
    NSPoint thePoint = NSMakePoint(selectionRect.origin.x + selectionRect.size.width, selectionRect.origin.y);
    
    if (fabs(thePoint.x - pt.x) <= 20.0 && fabs(thePoint.y - pt.y) <= 20.0)
        cornerDragged = YES;
    else {
        // was the click inside any area of selectionRect? drag the rect, centering it
        NSPoint centerPoint = NSMakePoint(selectionRect.origin.x + selectionRect.size.width / 2.0, selectionRect.origin.y + selectionRect.size.height / 2.0);
            if (fabs(centerPoint.x - pt.x) <= 20.0 && fabs(centerPoint.y - pt.y) <= 20.0) {
            // got a click inside
            contentDragged = YES;
        }
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (contentDragged) {
        // sanityse
        if (selectionRect.origin.x < 0)
            selectionRect.origin.x = 0;
            
        if (selectionRect.origin.x + selectionRect.size.width > [self frame].size.width)
            selectionRect.origin.x = [self frame].size.width - selectionRect.size.width;
            
        if (selectionRect.origin.y < 0)
            selectionRect.origin.y = 0;
            
        if (selectionRect.origin.y + selectionRect.size.height > [self frame].size.height)
            selectionRect.origin.y = [self frame].size.height - selectionRect.size.height;
            
        [self setNeedsDisplay: YES];
    }
    
    // need to notify delegate that we're done?
    if([theEvent clickCount] == 2)
		[_delegate performSelector: @selector(areaSelectionViewFinishedSelecting:) withObject: self];
    
    cornerDragged = contentDragged = NO;
}

- (NSRect)selectionRect
{
    return selectionRect;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint pt = [self convertPoint: [theEvent locationInWindow] fromView: nil];

    // do we have a selected corner? if so, allow it to move
    if (!cornerDragged && !contentDragged)
        return;

    if (cornerDragged) {
        // extract destination point
        // sanity check. is it lower than origin? invalidate
        if (pt.x <= selectionRect.origin.x || pt.x > [self frame].size.width)
            return;
         
        int tr_y = selectionRect.origin.y + selectionRect.size.height;
        
        if (pt.y >= tr_y)
            return;
        
        NSRect newRect = NSMakeRect(selectionRect.origin.x, pt.y, pt.x - selectionRect.origin.x, tr_y - pt.y);
        selectionRect = newRect;
    }
    
    if (contentDragged) {
        // sanity check that no content is out of screen
            
        selectionRect.origin.x = pt.x - selectionRect.size.width / 2;
        selectionRect.origin.y = pt.y - selectionRect.size.height / 2;
    }
    
    [self setNeedsDisplay:YES];
}

- (id)delegate
{
    return _delegate;
}

- (void)setDelegate:(id)aDelegate
{
    [aDelegate retain];
    [_delegate release];
    _delegate = aDelegate;
}

@end