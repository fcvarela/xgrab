//
//  D6NotificationView.m
//  xGrab
//
//  Created by Filipe Varela on 08/01/23.
//  Copyright 2008 Filipe Varela. All rights reserved.
//

#import "D6NotificationView.h"


@implementation D6NotificationView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
    NSBezierPath *glyphPath = [NSBezierPath bezierPath];
    unsigned count = [_glyphs count];
    unsigned i = 0;
    
    // get symbol font
    NSFont* font = [NSFont fontWithName:@".Keyboard" size:60];
    
    // estimate string length
    float stringLength = 0;
    for (i=0; i<count; i++) {
        NSGlyph glyph = [[_glyphs objectAtIndex: i] unsignedIntValue];
        stringLength += [font advancementForGlyph:glyph].width;
        if (i == 0 && _string != nil)
            stringLength *=2;
    }
    
    // posicionar com metade para cada lado
    float left = (float)(200.0f - stringLength / 2.0f);
    float bottom = -[font descender] + 10;
    
    for (i=0; i<count; i++) {
        NSGlyph glyph = [[_glyphs objectAtIndex: i] unsignedIntValue];
        
        [glyphPath moveToPoint: NSMakePoint(left, -[font descender] + 10)];
        [glyphPath appendBezierPathWithGlyph: glyph inFont: font];
        
        NSSize advancement = [font advancementForGlyph: glyph];
        left += advancement.width;
    }
    
    [[NSColor whiteColor] set];
    [glyphPath fill];
    
    // draw the string with a font
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont fontWithName:@"Helvetica" size: 60], NSFontAttributeName,
        [NSColor whiteColor], NSForegroundColorAttributeName, nil];
        
    if (_string) {
        NSAttributedString * attributedString = [[NSAttributedString alloc] initWithString:[_string capitalizedString] attributes: attributes];
        [attributedString drawInRect:NSMakeRect(left, bottom - 20, 200,80)];
        [attributedString release];
    }
}

- (void)setGlyphs:(NSArray *)glyphs andString:(NSString *)string
{
    [_glyphs release];
    [_string release];
    [glyphs retain];
    [string retain];
    
    _glyphs = glyphs;
    _string = string;
}

@end
