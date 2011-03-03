//
//  XGCompressor.m
//  xGrab
//
//  Created by Filipe Varela on 07/12/18.
//  Copyright 2007 Filipe Varela. All rights reserved.
//

#import "XGFrameExporter.h"
#import "XGQueueController.h"

static ICMCompressionSessionRef compressionSession = NULL;

#pragma mark -- STATIC METHODS

static OSStatus FrameCallback(void *encodedFrameOutputRefCon,ICMCompressionSessionRef session,OSStatus error,ICMEncodedFrameRef frame,void *reserved)
{
    if (error == noErr)
        [XGFrameExporter doneCompressingFrame:frame];
    
    return error;
}

static void SourceFrameTrackingCallback(void *sourceTrackingRefCon, ICMSourceTrackingFlags sourceTrackingFlags, void *sourceFrameRefCon, void *reserved)
{
    if (sourceTrackingFlags & kICMSourceTracking_LastCall) {
        // do nothing here...
    }
    
    if (sourceTrackingFlags & kICMSourceTracking_ReleasedPixelBuffer) {
        XGFrameReader *readerObject = (XGFrameReader *)sourceTrackingRefCon;
        XGQueueController *frameQueueController = [readerObject queueController];
        
        [frameQueueController addItemToFreeQueue:readerObject];
    }
}

@interface XGCompressor (PrivateMethods)

+ (void)createSharedCompressionSession:(CodecType)codec pixelsWide:(unsigned)width pixelsHigh:(unsigned)height options:(ICMCompressionSessionOptionsRef)options compressionTimeScale:(TimeScale)timescale;
- (void)compressFrame:(id)param;
@end

@implementation XGCompressor (PrivateMethods)

+ (void)createSharedCompressionSession:(CodecType)codec pixelsWide:(unsigned)width pixelsHigh:(unsigned)height options:(ICMCompressionSessionOptionsRef)options compressionTimeScale:(TimeScale)timescale
{
    ICMEncodedFrameOutputRecord record = {FrameCallback, NULL, NULL};
    OSStatus theError;
    
    if (!compressionSession) {
        theError = ICMCompressionSessionCreate(kCFAllocatorDefault, width, height, codec, timescale, options, NULL, &record, &compressionSession);
        
        if (theError)
            NSLog(@"ICMCompressionSessionCreate(): %i", theError);
    }
}

- (void)compressFrame:(id)param
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    @synchronized([XGCompressor class])
    {
        XGFrameReader *frameReaderObject = (XGFrameReader *)param;
        
        CVPixelBufferRef pixelBuffer = [frameReaderObject readScreenAsynchFinish];
        
        if (pixelBuffer) {
            OSStatus theError = -1;
            
            ICMSourceTrackingCallbackRecord callBackRec = {SourceFrameTrackingCallback, param};
            NSTimeInterval timestamp = [(XGFrameReader *)param bufferReadTime];
            NSTimeInterval duration = NAN;
            
            TimeScale compressionTimeScale = ICMCompressionSessionGetTimeScale(compressionSession);
            
            theError = ICMCompressionSessionEncodeFrame(compressionSession, pixelBuffer,
                       (timestamp >= 0.0 ? (SInt64)(timestamp * compressionTimeScale) : 0),
                       (duration >= 0.0 ? (SInt64)(duration * compressionTimeScale) : 0),
                       ((timestamp >= 0.0 ? kICMValidTime_DisplayOffsetIsValid : 0) | (duration >= 0.0 ? kICMValidTime_DisplayDurationIsValid : 0)),
                       NULL, &callBackRec, (void *)NULL);
            
            if (theError)
                NSLog(@"ICMCompressionSessionEncodeFrame(): %i", theError);
        } else {
            // no pixel buffer...
            XGQueueController *frameQueueController = [frameReaderObject queueController];
            [frameQueueController addItemToFreeQueue:frameReaderObject];
        }
    }
    
    [pool release];
}

@end

@implementation XGCompressor

+ (void)initialize
{
    // too carbonish for me... just lame
    EnterMovies();
}

- (id) initWithCodec:(CodecType)codec pixelsWide:(unsigned)width pixelsHigh:(unsigned)height
             options:(ICMCompressionSessionOptionsRef)options compressionTimeScale:(TimeScale)timescale
{
    if ((codec == 0) || (width == 0) || (height == 0) || (options == NULL) || timescale == 0) {
        NSLog(@"Input sanity check failed");
        [self release];
        return nil;
    }
    
    self = [super init];
    [XGCompressor createSharedCompressionSession:codec pixelsWide:width pixelsHigh:height options:options compressionTimeScale:timescale];
    
    return self;
}

+ (id) alloc
{
    if (self == [XGCompressor class])
        [self doesNotRecognizeSelector: _cmd];
    
    return [super alloc];
}

- (void) dealloc
{    
    if (compressionSession) {
        ICMCompressionSessionRelease(compressionSession);
        compressionSession = NULL;
    }
    
    [super dealloc];
    #ifdef __DEBUG_TARGET__
        NSLog(@"XGCompressor Dealloc");
    #endif
}

+ (ICMCompressionSessionOptionsRef) userOptions:(CodecType*)outCodecType frameRate:(double*)outFrameRate
{
	ICMMultiPassStorageRef			nullStorage = NULL;
	ComponentResult                 theError;
	ICMCompressionSessionOptionsRef	options;
	Boolean                         enable = true;
	CodecQ                          quality;
    SCTemporalSettings              temporalSettings;
    
    ComponentInstance component = OpenDefaultComponent(StandardCompressionType, StandardCompressionSubType);
	if(component == NULL) {
		NSLog(@"Coult not get Component.");
		return NULL;
	}
    
	// no defaults?
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    if ([def valueForKey:@"selectedFps"]==nil) {
        *outCodecType = kAnimationCodecType;
        *outFrameRate = 12.0f;
        quality = codecLowQuality;
    } else {
        // got defaults. use them
        NSNumber *codecIndex = [def valueForKey:@"selectedCodec"];
        NSNumber *codecValue = [[[XGCompressor availableCompressors] objectAtIndex: [codecIndex intValue]] valueForKey:@"Type"];
        *outCodecType = [codecValue intValue];
        *outFrameRate = [[def valueForKey: @"selectedFps"] doubleValue];
        
        switch ([[def valueForKey: @"selectedQuality"] intValue]) {
            case 0  : quality = codecMinQuality; break;
            case 1  : quality = codecLowQuality; break;
            case 2  : quality = codecNormalQuality; break;
            case 3  : quality = codecHighQuality; break;
            case 4  : quality = codecMaxQuality; break;
            case 5  : quality = codecLosslessQuality; break;
            default : quality = codecNormalQuality; break;
        }
    }
    
    temporalSettings.frameRate = X2Fix(*outFrameRate);
    temporalSettings.keyFrameRate = 60;
    temporalSettings.temporalQuality = quality;
    
    // Save the settings
    SCSetInfo(component, scTemporalSettingsType, &temporalSettings);
    CloseComponent(component);
	
	//Explicitely turn off multipass compression in case it was enabled by the user as we do not support it
    theError = ICMCompressionSessionOptionsCreate(NULL, &options);
	theError = ICMCompressionSessionOptionsSetProperty(options,kQTPropertyClass_ICMCompressionSessionOptions,
        kICMCompressionSessionOptionsPropertyID_MultiPassStorage,sizeof(ICMMultiPassStorageRef),&nullStorage);
	if (theError)
		NSLog(@"ICMCompressionSessionOptionsSetProperty(): %i", theError);
        
    // set the quality
    theError = ICMCompressionSessionOptionsSetProperty(options,kQTPropertyClass_ICMCompressionSessionOptions,
        kICMCompressionSessionOptionsPropertyID_Quality,sizeof(CodecQ),&quality);
    if (theError)
        NSLog(@"ICMCompressionSessionOptionsSetProperty(): %i", theError);
    
	// We must set this flag to enable P or B frames.
	theError = ICMCompressionSessionOptionsSetAllowTemporalCompression( options, true );
	if (theError)
		NSLog(@"ICMCompressionSessionOptionsSetAllowTemporalCompression(): %i", theError);
	
    // We must set this flag to enable B frames.
	theError = ICMCompressionSessionOptionsSetAllowFrameReordering( options, true );
	if (theError)
		NSLog(@"ICMCompressionSessionOptionsSetAllowFrameReordering(): %i", theError);
	
	// Set the maximum key frame interval, also known as the key frame rate.
	theError = ICMCompressionSessionOptionsSetMaxKeyFrameInterval( options, 60 );
	if (theError)
		NSLog(@"ICMCompressionSessionOptionsSetMaxKeyFrameInterval(): %i", theError);
    
	// This allows the compressor more flexibility (ie, dropping and coalescing frames).
	theError = ICMCompressionSessionOptionsSetAllowFrameTimeChanges( options, true );
	if (theError)
        NSLog(@"ICMCompressionSessionOptionsSetAllowFrameTimeChanges(): %i", theError);
	
	// We need durations when we store frames.
	theError = ICMCompressionSessionOptionsSetDurationsNeeded( options, true );
	if (theError)
        NSLog(@"ICMCompressionSessionOptionsSetDurationsNeeded(): %i", theError);
    
	// Enable the compressor to call the encoded-frame callback from a different thread. 
	theError = ICMCompressionSessionOptionsSetProperty(
        options,
        kQTPropertyClass_ICMCompressionSessionOptions,
        kICMCompressionSessionOptionsPropertyID_AllowAsyncCompletion,
        sizeof(Boolean),
        &enable);
	
    if (theError)
		NSLog(@"SCCopyCompressionSessionOptions(): %i", theError);
    
	return (ICMCompressionSessionOptionsRef)[(id)options autorelease];
}

- (BOOL)detachFrameCompression:(XGFrameReader *)frameReaderObject
{
    [NSThread detachNewThreadSelector:@selector(compressFrame:) toTarget:self withObject:frameReaderObject];
	return YES;
}

+ (BOOL)flushFrames
{
    OSStatus	theError;
    
    @synchronized([XGCompressor class])
	{
		//Flush pending frames in compression session
        theError = ICMCompressionSessionCompleteFrames(compressionSession, true, 0, 0);
		if (theError)
            NSLog(@"ICMCompressionSessionCompleteFrames() failed with error %i", theError);
	}
	
	return (theError == noErr ? YES : NO);
}

// Placeholder for additional processing you may want to do
+ (void) doneCompressingFrame:(ICMEncodedFrameRef)frame
{
	//Do any additional processing here
    // use this to disable unused parameter warning
    if (frame) {};
}

+ (NSArray *) availableCompressors
{
    // get component count
    ComponentDescription lComponentDescription = {compressorComponentType, 0, 0, 0, 0};
    long lComponentCount = CountComponents(&lComponentDescription);
    
    // create array with count elements
    NSMutableArray *compressorArray = [NSMutableArray arrayWithCapacity: lComponentCount];
    
    // alloc temporary data for components
    Component lID = 0;
    Handle lName = NewHandleClear(200);
    Handle lInfo = NewHandleClear(200);
    Handle lIcon = NewHandleClear(200);
    do {
        lID = FindNextComponent(lID, &lComponentDescription);
        if (lID){
            ComponentDescription lDescriptor = {0, 0, 0, 0, 0};
            GetComponentInfo(lID, &lDescriptor, lName, lInfo, lIcon);
            
            // append component name to array and clean its contents
            [compressorArray addObject:
                [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSString stringWithCString: (char *)*lName+1], @"Name",
                    [NSNumber numberWithUnsignedLongLong: lDescriptor.componentSubType], @"Type",
                    NULL]];
            
            // clear the char vector
            bzero((char *)*lName, strlen((char *)*lName));
        }
    } while (lID);
    
    // clear handles
    DisposeHandle(lName);
    DisposeHandle(lInfo);
    DisposeHandle(lIcon);
    
    // debug the component list
    NSArray *compressors = [[NSArray alloc] initWithArray: compressorArray];
    return [compressors autorelease];
}

@end

// FUNCTIONS
NSString *OSTypeToNSString(OSType inType)
{
    char theString[12];
    UInt8 i;
    
    // OSTypes are native endian and we want big-endian
    inType = EndianU32_NtoB(inType);
    
    unsigned char *theCharsIterator = (unsigned char *)&inType;
    UInt8 charCount = 0;
    unsigned char theHex[] = "0123456789abcdef";
    
    if (0 != inType) {
  
        for (i = 0; i < 4; i++) {
            if ((' ' <= *theCharsIterator) && (*theCharsIterator <= 126)) {
                theString[charCount++] = *theCharsIterator;
            } else {
                theString[charCount++] = '$'; // ah, dollar signs meaning hexadecimal...so nostalgic
                theString[charCount++] = theHex[*theCharsIterator >> 4];
                theString[charCount++] = theHex[*theCharsIterator & 15];
            }
            theCharsIterator++;
        }
    }
    
    return [NSString stringWithCString:theString length:charCount];
}
