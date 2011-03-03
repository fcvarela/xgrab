//
//  XGQueueController.h
//  xGrab
//
//  Created by Filipe Varela on 07/12/18.
//  Copyright 2007 Filipe Varela. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "D6Queue.h"

@interface XGQueueController : NSObject
{
    NSString *mFreeQueueMutex, *mFilledQueueMutex;
    D6Queue *mFreeQueue, *mFilledQueue;
}

-(id)initWitFrameReaderCount:(unsigned)objectCount glContext:(NSOpenGLContext *)context pixelsWide:(unsigned)width pixelsHigh:(unsigned)height;
-(void)addItemToFreeQueue:(id)anItem;
-(void)addItemToFilledQueue:(id)anItem;
-(id)removeLastItemFromFreeQueue;
-(id)removeLastItemFromFilledQueue;

@end
