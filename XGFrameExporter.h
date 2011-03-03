//
//  XGFrameExporter.h
//  xGrab
//
//  Created by Filipe Varela on 07/12/18.
//  Copyright 2007 Filipe Varela. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XGCompressor.h"

@interface XGFrameExporter : XGCompressor

-(id)initWithPath:(NSString *)path codec:(CodecType)codec pixelsWide:(unsigned)width pixelsHigh:(unsigned)height
          options:(ICMCompressionSessionOptionsRef)options;
-(BOOL)exportFrame:(XGFrameReader *)frameReaderObject;
+(void)doneCompressingFrame:(ICMEncodedFrameRef)frame;

@end
