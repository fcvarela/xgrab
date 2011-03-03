//
//  XGMainController.m
//  OpenGLScreenCapture
//
//  Created by Filipe Varela on 07/12/18.
//  Copyright 2007 Filipe Varela. All rights reserved.
//

#include <unistd.h>
#import "XGMainController.h"
#import "D6LicenseValidator.h"

#define kNumReaderObjects 15

static CVReturn RenderCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext) {
    return [(XGMainController *)displayLinkContext renderCallback:inOutputTime flagsOut:flagsOut];
}

CFStringRef TranslateHotKey(UInt16 virtualKeyCode)
{
    OSStatus theStatus;
    KeyboardLayoutRef theCurrentLayout;
    const UCKeyboardLayout *uchrData;
    const void *kchrData;
    CFStringRef translatedString;
    CFMutableStringRef uppercaseString;

    theStatus = KLGetCurrentKeyboardLayout(&theCurrentLayout);
    theStatus = KLGetKeyboardLayoutProperty(theCurrentLayout,
        kKLuchrData, (const void **)&uchrData);

    if (theStatus == noErr && uchrData != 0) {
        // uchr is present
        
        UniChar buf[256];
        UniCharCount actualStringLength;
        UInt32 deadKeyState = 0;
        
        theStatus = UCKeyTranslate(
            uchrData,
            virtualKeyCode,
            kUCKeyActionDisplay,
            cmdKey >> 8, // !!!
            LMGetKbdType(),
            kUCKeyTranslateNoDeadKeysMask,
            &deadKeyState,
            sizeof(buf)/sizeof(UniChar),
            &actualStringLength,
            buf
        );
        
        translatedString = CFStringCreateWithCharacters(kCFAllocatorDefault,
            buf, actualStringLength);
        
    } else {
    
        UInt32 chars;
        UInt32 deadKeyState = 0;
        TextEncoding keyboardEncoding;
        
        theStatus = KLGetKeyboardLayoutProperty(theCurrentLayout,
            kKLKCHRData, &kchrData);
        
        chars = KeyTranslate(
            kchrData,
            (virtualKeyCode & 0x7F) | cmdKey,  // !!!
            &deadKeyState);

        theStatus = UpgradeScriptInfoToTextEncoding(
            (ScriptCode)GetScriptManagerVariable(smKeyScript),
            kTextLanguageDontCare,
            kTextRegionDontCare,
            0, // no font name
            &keyboardEncoding
        );
        
        // There shouldn't be more than one character if dead key state
        // was zero?
        // Accented characters take a single byte in legacy encodings.
        translatedString = CFStringCreateWithBytes(kCFAllocatorDefault,
            (UInt8*)&chars + 3, 1, keyboardEncoding, FALSE);
    }

    uppercaseString = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, translatedString);
    CFStringUppercase(uppercaseString, 0);

    CFRelease(translatedString);

    return uppercaseString;
}

CGEventRef XGCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
    if ([(XGMainController *)refcon capturing] == NO)
        return event;
    
    // Paranoid sanity check. if not a keydown or feature disabled, return immediately
    if (type != kCGEventKeyDown)
        return event;
        
    // Get incoming keycode
    CGKeyCode keycode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);

    // get keyboard font
    NSFont *font = [NSFont fontWithName:@".Keyboard" size:13];
    
    // glyph array init
    NSMutableArray *glyphArray = [NSMutableArray arrayWithCapacity: 0];
    
    // get event flags
    CGEventFlags flags = CGEventGetFlags(event);
    
    // test flags and append glyph to array
    if (flags & kCGEventFlagMaskCommand)
        [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"propellor"]]];
    else // don't show anything other than command combinations
        return event;
        
    if (flags & kCGEventFlagMaskAlternate)
        [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"option"]]];
        
    if (flags & kCGEventFlagMaskControl)
        [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"control"]]];

    if (flags & kCGEventFlagMaskShift)
        [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"arrowupwhite"]]];
        
    // need to append special keys which are obviously not flags (arrows, enter, cr, backspace, delete, page[udlr], f_[1-15], eject, esc, tab
    // these are never combined with regular keys so we need to return them immediately
    int gotSpecialKey = 0;
    
    switch (keycode) {
        // arrow keys
        case 123 : [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"arrowleft"]]]; gotSpecialKey = 1; break;
        case 124 : [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"arrowright"]]]; gotSpecialKey = 1; break;
        case 125 : [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"arrowdown"]]]; gotSpecialKey = 1; break;
        case 126 : [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"arrowup"]]]; gotSpecialKey = 1; break;
        
        // others
        case 117: [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"deleteright"]]]; gotSpecialKey = 1; break;
        case 53 : [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"escape"]]]; gotSpecialKey = 1; break;
        case 48 : [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"arrowtabright"]]]; gotSpecialKey = 1; break;
        case 76 : [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"enter"]]]; gotSpecialKey = 1; break;
        case 36 : [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"carriagereturn"]]]; gotSpecialKey = 1; break;
        case 51 : [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"deleteleft"]]]; gotSpecialKey = 1; break;
        
        case 122: [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"F_one"]]]; gotSpecialKey = 1; break;
        case 120: [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"F_two"]]]; gotSpecialKey = 1; break;
        case 99 : [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"F_three"]]]; gotSpecialKey = 1; break;
        case 118: [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"F_four"]]]; gotSpecialKey = 1; break;
        case 96 : [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"F_five"]]]; gotSpecialKey = 1; break;
        case 97 : [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"F_six"]]]; gotSpecialKey = 1; break;
        case 98 : [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"F_seven"]]]; gotSpecialKey = 1; break;
        case 100: [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"F_eight"]]]; gotSpecialKey = 1; break;
        case 101: [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"F_nine"]]]; gotSpecialKey = 1; break;
        case 109: [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"F_one_zero"]]]; gotSpecialKey = 1; break;
        case 103: [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"F_one_one"]]]; gotSpecialKey = 1; break;
        case 111: [glyphArray addObject: [NSNumber numberWithUnsignedInt: [font glyphWithName:@"F_one_two"]]]; gotSpecialKey = 1; break;
    }
    
    NSString *str;
    
    if (!gotSpecialKey) {
        CFStringRef ref = TranslateHotKey(keycode);
        str = [NSString stringWithFormat:@"%@", ref];
    } else 
        str = nil;
    [(XGMainController *)refcon registerNotificationWithGlyphs: glyphArray andString: str];
    
    return event;
}

@implementation XGMainController
- (void)registerNotificationWithGlyphs:(NSArray *)glyphs andString:(NSString *)string;
{
    if (_capturing == NO || [[NSUserDefaults standardUserDefaults] boolForKey:@"hotkeysActive"] == NO)
        return;
    
    if (notificationWindow == nil)
        return;
        
    if (notificationView == nil)
        return;
    
    [notificationView setGlyphs: glyphs andString: string];
    [notificationView setNeedsDisplay: YES];
    [notificationWindow orderFront: self];
    
    // now we invalidade the notification timer and add some more time (1.0s)
    [notificationTimer invalidate];
    notificationTimer = [NSTimer scheduledTimerWithTimeInterval: 0.8f target: self selector: @selector(handleTimer:) userInfo: nil repeats: NO];
    [notificationTimer retain];
}

-(void)handleTimer:(id)sender
{
    [notificationWindow orderOut:self];
}

- (id)init
{
    if ((self = [super init])) {
        GLContext = nil;
        exporterObject = nil;
    }
    
    // workspace to open license file. make sure it exists
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [@"~/Library/Preferences/com.dev6.xGrab.xgrablicense" stringByExpandingTildeInPath];
    if ([fileManager fileExistsAtPath: path]) {
        if ([ws openFile: path] == NO) {
            // display alert telling user about the capture timeout
            // and date limit
            [D6LicenseValidator checkLicense:nil];
        }
    }
    
    // install keyboard tap
    CFMachPortRef eventTap;
    CGEventMask eventMask;
    CFRunLoopSourceRef runLoopSource;
    
    // register for key down only
    eventMask = ((1 << kCGEventKeyDown));// | (1 << kCGEventKeyUp));
    eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, eventMask, XGCGEventCallback, self);
    if (!eventTap) {
        /*NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
            NSLocalizedStringFromTable(@"UniversalAccessError",@"Localizations",nil),NSLocalizedDescriptionKey,
            NSLocalizedStringFromTable(@"UniversalAccessErrorReason",@"Localizations",nil),NSLocalizedFailureReasonErrorKey,
            nil];
        NSError *outError = [NSError errorWithDomain:@"com.dev6.xGrab" code:-2 userInfo: errorDict];
        NSAlert *theAlert = [NSAlert alertWithError:outError];
        [theAlert runModal];
        */
        return self;
    }

    // Create a run loop source.
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);

    // Add to the current run loop.
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);

    // Enable the event tap.
    CGEventTapEnable(eventTap, true);
    
    return self;
}

// notification
- (void)sharedMovieSaved
{
    _capturing = NO;
}

- (void)awakeFromNib
{
    // install our menu item
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
	menuItem = [bar statusItemWithLength: NSVariableStatusItemLength];
	//NSImage *menuImage = [[NSImage alloc]initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"xgrab" ofType:@"png"]];
	//[menuItem setImage: menuImage];
    [menuItem setTitle: @"xG"];
	[menuItem retain];

	[menuItem setHighlightMode: YES];
	[menuItem setMenu: menuItemMenu];
    
    [self buildAreaSelectionWindow];
}

- (void)applicationWillTerminate:(NSNotification*)notification
{
    if (_capturing)
        [self cancelCapture];
}

- (NSRect)screenRect
{
    CGRect screenRect = CGDisplayBounds(CGMainDisplayID());
    return NSMakeRect(screenRect.origin.x, screenRect.origin.y, screenRect.size.width, screenRect.size.height);
}

- (void)setSelectionRect:(NSRect)aRect
{
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(aRect) forKey:@"selectionRect"];
    NSLog(@"finished setting selection rect");
    
    // orderout on areaSelectionWindow
    [areaSelectionWindow orderOut: self];
}

- (void)buildAreaSelectionWindow
{
    areaSelectionWindow = [[NSWindow alloc]initWithContentRect: [self screenRect] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [areaSelectionWindow setBackgroundColor: [NSColor clearColor]];
    [areaSelectionWindow setIgnoresMouseEvents: NO];
    [areaSelectionWindow setLevel: NSStatusWindowLevel];
    [areaSelectionWindow setAlphaValue: 1.0f];
    [areaSelectionWindow setOpaque: NO];
    [areaSelectionWindow setHasShadow: NO];
    [areaSelectionWindow orderFrontRegardless];
    areaSelectionView = [[D6AreaSelectionView alloc] initWithFrame: [areaSelectionWindow frame] andSelection: NSRectFromString([[NSUserDefaults standardUserDefaults] objectForKey:@"selectionRect"])];
    
    // register as delegate to get selection notification
    [areaSelectionView setDelegate: self];
    
    // and push the view to the window
    [areaSelectionWindow setContentView: areaSelectionView];
}

- (void)areaSelectionViewFinishedSelecting:(D6AreaSelectionView *)sender
{
    // get rect from sender and put it in preferences
    [self setSelectionRect: [sender selectionRect]];
}

- (void)buildNotificationWindow
{
    // build notification window
    NSRect aRect = NSMakeRect(
        displayRect.origin.x + displayRect.size.width / 2.0f - 200.0f,
        displayRect.origin.y + 100.0f,
        400.0f,
        100.0f
    );
    notificationWindow = [[NSWindow alloc]initWithContentRect: aRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [notificationWindow setBackgroundColor: [NSColor /*clearColor*/blackColor]];
    [notificationWindow setIgnoresMouseEvents:YES];
    [notificationWindow setLevel: NSStatusWindowLevel];
    [notificationWindow setAlphaValue:0.6f];
    [notificationWindow setOpaque:NO];
    [notificationWindow setHasShadow: YES];
    //[notificationWindow orderFrontRegardless];
    
    // build notification view
    notificationView = [[D6NotificationView alloc] initWithFrame:aRect];
    [notificationWindow setContentView: notificationView];
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
    NSOpenGLPixelFormatAttribute attributes[] = {NSOpenGLPFAFullScreen,NSOpenGLPFAScreenMask,CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay),
        (NSOpenGLPixelFormatAttribute)0 };
    
	GLPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
	NSAssert( GLPixelFormat != nil, @"No renderer");
	if (!GLPixelFormat)
        return;
    
	//Create OpenGL context used to render
	GLContext = [[NSOpenGLContext alloc] initWithFormat:GLPixelFormat shareContext:nil];
	NSAssert( GLContext != nil, @"NSOpenGLContext init error");
	[GLContext makeCurrentContext];
	[GLContext setFullScreen];
    
	CGDirectDisplayID displayID = CGMainDisplayID();
	NSAssert( displayID != nil, @"CGMainDisplayID error");
}

- (void)compressFrames
{
    if (startTime == 0.0) {
        NSTimeInterval timeInt = [NSDate timeIntervalSinceReferenceDate];
        startTime = timeInt;
    }
    
    XGFrameReader *freeReaderObject = [frameQueueController removeLastItemFromFreeQueue];
    if (freeReaderObject) {
        [freeReaderObject setBufferReadTime:startTime];
        [freeReaderObject readScreenAsynchOnSeparateThread];
    }
    
    XGFrameReader *filledReaderObject = [frameQueueController removeLastItemFromFilledQueue];
    if (filledReaderObject)
        [exporterObject exportFrame:filledReaderObject];
}

- (CVReturn)renderCallback:(const CVTimeStamp *)timeStamp flagsOut:(CVOptionFlags *)flagsOut
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    [self compressFrames];
    
    [pool release];
    
    return kCVReturnSuccess;
}

- (IBAction)finishCapture:(id)sender
{
    if (_capturing)
        [self cancelCapture];
}

- (void)cancelCapture
{
    if (displayLink) {
        CVDisplayLinkStop(displayLink);
        CVDisplayLinkRelease(displayLink);
        displayLink = NULL;
    }
    
    if (exporterObject) {
        // will trigger shared movie save
        [exporterObject release];
        exporterObject = nil;
    }
    
    if (frameQueueController) {
        // no prob. as soon as the framereaders release their ref, it'll dealloc
        [frameQueueController release];
        frameQueueController = nil;
    }
    
    if (notificationView)
        [notificationView release];
    
    if (notificationWindow)
        [notificationWindow release];
}  

- (IBAction)beginCapture:(id)sender
{
    NSSavePanel * savePanel = [NSSavePanel savePanel];
    ICMCompressionSessionOptionsRef options;
    CodecType codec;
    double framerate;
    
    id appDelegate = [[NSApplication sharedApplication] delegate];
    NSMutableString *reg = [NSMutableString stringWithString: @"a"];
    [appDelegate performSelector:@selector(isRegistered:) withObject:reg];
    
    // where to save?
    [savePanel setRequiredFileType:@"mov"];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setCanSelectHiddenExtension:YES];
    if (
        ([savePanel runModalForDirectory:[@"~/Desktop" stringByExpandingTildeInPath] file:@"xGrab Movie.mov"] == NSOKButton) &&
        (options = [XGCompressor userOptions:&codec frameRate:&framerate])
    ) {
        unsigned int widthNumber, heightNumber, localWidth, localHeight;
        
        // get display rect
        if (CGMainDisplayID())
            displayRect = CGDisplayBounds(CGMainDisplayID());
        
        widthNumber = [[NSNumber numberWithFloat: displayRect.size.width] unsignedIntValue];
        heightNumber = [[NSNumber numberWithFloat: displayRect.size.height] unsignedIntValue];
        
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        if ([defs boolForKey:@"outResFull"] == YES) {
            localWidth = [[defs objectForKey:@"outResWidth"] unsignedIntValue];
            localHeight = [[defs objectForKey:@"outResHeight"] unsignedIntValue];
        } else {
            localWidth = widthNumber;
            localHeight = heightNumber;
        }
        
        // init exporter for session
        exporterObject = [[XGFrameExporter alloc] initWithPath:[savePanel filename] codec:codec pixelsWide:localWidth pixelsHigh:localHeight options:options];
        
        // register for exporter notification
        [[NSNotificationCenter defaultCenter] removeObserver: self];
        [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(sharedMovieSaved) name:@"sharedMovieSaved" object: nil];
        
        // init frame queue controller
        frameQueueController = [[XGQueueController alloc] initWitFrameReaderCount: kNumReaderObjects glContext:GLContext pixelsWide:widthNumber pixelsHigh:heightNumber];
        
        startTime = 0.0;
        CVDisplayLinkCreateWithCGDisplay(kCGDirectMainDisplay, &displayLink);
        
        if (displayLink != NULL)
        {
            CVDisplayLinkSetCurrentCGDisplay(displayLink, kCGDirectMainDisplay);
            CVDisplayLinkSetOutputCallback(displayLink, &RenderCallback, self);
            CVDisplayLinkStart(displayLink);
        }
        
        _capturing = YES;
        [self buildNotificationWindow];
        
        // enforce timeout
        if ([reg isEqualToString:@"2"]) {
            // init timer to call [self cancelCapture]
            [self performSelector:@selector(finishCapture:) withObject:self afterDelay: 25.0f];
        }
    }
}

- (BOOL)capturing
{
    return _capturing;
}

// dock menu
- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
    return nil;
    //menuItemMenu;
}

- (IBAction)showPreferencesWindow:(id)sender
{
    if (!preferencesController)
		preferencesController = [[XGPreferencesController alloc] init];
        
    [[preferencesController window] makeKeyAndOrderFront: self];
}

@end

@implementation XGMainController (PrivateMethods)
-(void)setRegistered
{
    _registered = YES;
}

-(void)isRegistered:(NSMutableString *)input
{
    if (_registered)
        [input setString: @"1"];
    else
        [input setString: @"2"];
}
@end
