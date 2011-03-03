//
//  XGCompressor.h
//  xGrab
//
//  Created by Filipe Varela on 07/12/18.
//  Copyright 2007 Filipe Varela. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>
#import <Quartz/Quartz.h>
#import "XGFrameReader.h"

@interface XGCompressor : NSObject

+(ICMCompressionSessionOptionsRef)userOptions:(CodecType*)outCodecType frameRate:(double *)outFrameRate;
-(id)initWithCodec:(CodecType)codec pixelsWide:(unsigned)width pixelsHigh:(unsigned)height
           options:(ICMCompressionSessionOptionsRef)options compressionTimeScale:(TimeScale)timescale;
-(BOOL)detachFrameCompression:(XGFrameReader *)frameReaderObj;
+(BOOL)flushFrames;
+(void)doneCompressingFrame:(ICMEncodedFrameRef)frame;
+(NSArray *)availableCompressors;

@end

NSString *OSTypeToNSString(OSType inType);
