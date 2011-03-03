//
//  XGMainController.h
//  OpenGLScreenCapture
//
//  Created by Filipe Varela on 07/12/18.
//  Copyright 2007 Filipe Varela. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XGFrameExporter.h"
#import "XGPreferencesController.h"
#import "D6NotificationView.h"
#import "D6AreaSelectionView.h"

@interface XGMainController : NSObject
{
    IBOutlet id menuItemMenu;
    NSWindow *notificationWindow, *areaSelectionWindow;
    D6NotificationView *notificationView;
    D6AreaSelectionView *areaSelectionView;
    
    NSTimer *notificationTimer;
    
    BOOL _capturing;
    
	NSStatusItem *menuItem;
    
    NSTimeInterval startTime;
    
    NSOpenGLContext *GLContext;
    NSOpenGLPixelFormat *GLPixelFormat;
    
    CGRect displayRect;
    CVDisplayLinkRef displayLink;
    
    XGQueueController *frameQueueController;
    XGFrameExporter *exporterObject;
    XGFrameReader *frameReader;
    
    XGPreferencesController *preferencesController;
    
    @private
    BOOL _registered;
}

- (IBAction)showPreferencesWindow:(id)sender;

- (IBAction)beginCapture:(id)sender;
- (IBAction)finishCapture:(id)sender;
- (void)cancelCapture;

- (CVReturn)renderCallback:(const CVTimeStamp *)timeStamp flagsOut:(CVOptionFlags *)flagsOut;
- (BOOL)capturing;

// dock menu
- (NSMenu *)applicationDockMenu:(NSApplication *)sender;

// notification of hotkeys
- (void)registerNotificationWithGlyphs:(NSArray *)glyphs andString:(NSString *)string;

// windows
- (void)buildNotificationWindow;
- (void)buildAreaSelectionWindow;

// selection notification (delegate method)
- (void)areaSelectionViewFinishedSelecting:(D6AreaSelectionView *)sender;

@end

// protos
CGEventRef XGCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);
CFStringRef TranslateHotKey(UInt16 virtualKeyCode);
