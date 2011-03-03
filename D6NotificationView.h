//
//  D6NotificationView.h
//  xGrab
//
//  Created by Filipe Varela on 08/01/23.
//  Copyright 2008 Filipe Varela. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface D6NotificationView : NSView
{
    NSArray *_glyphs;
    NSString *_string;
}

- (void)setGlyphs:(NSArray *)glyphs andString:(NSString *)string;

@end
