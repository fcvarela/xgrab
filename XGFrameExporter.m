//
//  XGFrameExporter.m
//  xGrab
//
//  Created by Filipe Varela on 07/12/18.
//  Copyright 2007 Filipe Varela. All rights reserved.
//

#import "XGFrameExporter.h"

#define kTimeScale 1000000

static Movie mMovie = NULL;
static NSString *sharedMoviePath;
static DataHandler mDataHandler = NULL;
static Track mTrack = NULL;
//static Track mTrackAudio = NULL;
static Media mMedia = NULL;
//static Media mMediaAudio = NULL;

@interface XGFrameExporter (PrivateMethods)
+(void)createSharedMovie:(NSString *)path pixelsWide:(unsigned)width pixelsHigh:(unsigned)height movieTimeScale:(TimeScale)timescale;
+(void)writeAndCloseMovie;
@end

@implementation XGFrameExporter (PrivateMethods)

+ (void) writeAndCloseMovie
{
    OSErr theError;
    
    [XGFrameExporter flushFrames];
    
    @synchronized([XGFrameExporter class])
    {
        if (mMedia) {
            theError = EndMediaEdits(mMedia);
            if (theError)
                NSLog(@"EndMediaEdits(): %i", theError);
                
            theError = ExtendMediaDecodeDurationToDisplayEndTime(mMedia, NULL);
            if (theError)
                NSLog(@"ExtendMediaDecodeDurationToDisplayEndTime(): %i", theError);
                
			theError = InsertMediaIntoTrack(mTrack, (TimeValue)0, (TimeValue)0, (TimeValue)GetMediaDisplayDuration(mMedia), fixed1);
			if(theError)
                NSLog(@"InsertMediaIntoTrack(): %i", theError);
			
			theError = AddMovieToStorage(mMovie, mDataHandler);
			if(theError)
                NSLog(@"AddMovieToStorage(): %i", theError);
		}
		
		//Close movie file
		if (mDataHandler)
            CloseMovieStorage(mDataHandler);
            
		if(mMovie)
            DisposeMovie(mMovie);
		
		mMovie=NULL;
		mDataHandler=NULL;
		mTrack=NULL;
		mMedia=NULL;
        
        // issue notification
        [[NSNotificationCenter defaultCenter] postNotificationName:@"sharedMovieSaved" object: nil];
        
        // ask workspace to open movie
        if (sharedMoviePath != nil)
            [[NSWorkspace sharedWorkspace] openFile: sharedMoviePath];
	}
}

+(void)createSharedMovie:(NSString*)path pixelsWide:(unsigned)width pixelsHigh:(unsigned)height movieTimeScale:(TimeScale)timescale
{
	if (mMovie == NULL) {
		OSErr theError = noErr;
		Handle dataRef;
		OSType dataRefType;
        
        // adapt path to add version number
        
		//Create movie file
		theError = QTNewDataReferenceFromFullPathCFString((CFStringRef)path, kQTNativeDefaultPathStyle, 0, &dataRef, &dataRefType);
		if (theError) {
			NSLog(@"QTNewDataReferenceFromFullPathCFString(): %i", theError);
			[self release];
		}
		
        // Create a movie for this file (data ref)
		theError = CreateMovieStorage(dataRef, dataRefType, 'TVOD', smCurrentScript, createMovieFileDeleteCurFile, &mDataHandler, &mMovie);
		if (theError) {
			NSLog(@"CreateMovieStorage(): %i", theError);
			[self release];
		}
        
		// dispose of the data reference handle - we no longer need it
		DisposeHandle(dataRef);
		
		// Add track. Change WIDTH/HEIGHT of final movie here
        mTrack = NewMovieTrack(mMovie, width << 16, height << 16, 0);
        theError = GetMoviesError();
		if (theError) {
			NSLog(@"NewMovieTrack(): %i", theError);
			[self release];
		}
		
		//Create track media
		mMedia = NewTrackMedia(mTrack, VideoMediaType, timescale, 0, 0);
		theError = GetMoviesError();
		if (theError) {
			NSLog(@"NewTrackMedia(): %i", theError);
			[self release];
		}
		
		//Prepare media for editing
		theError = BeginMediaEdits(mMedia);
		if (theError) {
			NSLog(@"BeginMediaEdits(): %i", theError);
			[self release];
		}
        /*
        // add audio track
        mTrackAudio = NewMovieTrack(mMovie, 0, 0, kFullVolume);
        theError = GetMoviesError();
		if (theError) {
			NSLog(@"NewMovieTrack[audio](): %i", theError);
			[self release];
		}
        
        // create track audio media
        mMediaAudio = NewTrackMedia(mTrackAudio, SoundMediaType, mAudioSampleRate, NULL, 0);
        */
        [sharedMoviePath release];
        sharedMoviePath = [[NSString stringWithString: path] retain];
	}
}

@end

@implementation XGFrameExporter

- (id) initWithCodec:(CodecType)codec pixelsWide:(unsigned)width pixelsHigh:(unsigned)height
             options:(ICMCompressionSessionOptionsRef)options compressionTimeScale:(TimeScale)timescale
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id) initWithPath:(NSString*)path codec:(CodecType)codec
         pixelsWide:(unsigned)width
         pixelsHigh:(unsigned)height
            options:(ICMCompressionSessionOptionsRef)options
{
	//Check parameters
    if (![path length]) {
		[self release];
		return nil;
	}
	
	//Initialize super class - ERROR INSIDE super
	if ((self = [super initWithCodec:codec pixelsWide:width pixelsHigh:height options:options compressionTimeScale:kTimeScale]))
		[XGFrameExporter createSharedMovie:path pixelsWide:width pixelsHigh:height movieTimeScale:kTimeScale];
	else
        NSLog(@"ERROR ON INIT");
        
	return self; 
}

- (void) dealloc
{
    [XGFrameExporter writeAndCloseMovie];
    [super dealloc];
    #ifdef __DEBUG_TARGET__
        NSLog(@"XGFrameExporter Dealloc");
    #endif
}

- (BOOL) exportFrame:(XGFrameReader *)frameReaderObject
{
	BOOL ret = [super detachFrameCompression:frameReaderObject];
    return ret;
}

+(void) doneCompressingFrame:(ICMEncodedFrameRef)frame
{
	@synchronized([XGFrameExporter class])
	{
		if (mMedia) {
			OSErr theError;
			
			//Add frame to track media - Ignore the last frame which will have a duration of 0
			if(ICMEncodedFrameGetDecodeDuration(frame) > 0) {
                //  Adds sample data and description from an encoded frame to a media.
				theError = AddMediaSampleFromEncodedFrame(mMedia, frame, NULL);
				if (theError)
                    NSLog(@"AddMediaSampleFromEncodedFrame(): %i", theError);
			}
		}
		
        // call the FrameCompressor completion routine to perform any additional housekeeping
        // (we don't do anything extra in our example...)
        [XGCompressor doneCompressingFrame:frame];
	}
}
@end
