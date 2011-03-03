//
//  XGFrameReader.h
//  xGrab
//
//  Created by Filipe Varela on 07/12/18.
//  Copyright 2007 Filipe Varela. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "XGQueueController.h"

typedef int CGSConnection;
typedef CGSConnection *CGSConnectionRef;
extern CGSConnectionRef _CGSDefaultConnection(void);
extern void CGSInitialize();
extern CGError CGSGetGlobalCursorDataSize(CGSConnectionRef connection, int* size);
extern CGError CGSGetGlobalCursorData(CGSConnectionRef connection,unsigned char* cursorData,int* size,int* unknown,CGRect* cursorRect,CGPoint* hotspot,int* depth,int* components,int* bitsPerComponent);

@interface XGFrameReader : NSObject
{
    @private
    NSOpenGLContext *mGLContext;
    unsigned mWidth, mHeight, mBufferRowBytes;
    
    NSPoint cursorPosition;
    CGPoint cursorHotSpot;
    CGRect cursorRect;
    int cursorDataSize, cursorPlanes, cursorDepth, cursorComponents, cursorBitsPerComponent;
    unsigned char cursorImageBuffer[65535];
    
    unsigned long mTextureName;
    CVPixelBufferPoolRef mBufferPool;
    CVPixelBufferRef mPixelBuffer;
    unsigned char *mBaseAddress;
    NSTimeInterval mStartTime, mRecordTime;
    XGQueueController *mQueueController;
}

- (id)initWithOpenGLContext:(NSOpenGLContext*)context pixelsWide:(unsigned)width pixelsHigh:(unsigned)height queueController:(XGQueueController *)controller;
- (BOOL)readScreenAsynchBegin;
- (CVPixelBufferRef)readScreenAsynchFinish;
- (void)readScreenAsynchOnSeparateThread;
- (NSTimeInterval)bufferReadTime;
- (void)setBufferReadTime:(NSTimeInterval)aStartTime;
- (XGQueueController *)queueController;

@end
