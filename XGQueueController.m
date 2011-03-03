//
//  XGQueueController.m
//  xGrab
//
//  Created by Filipe Varela on 07/12/18.
//  Copyright 2007 Filipe Varela. All rights reserved.
//

#import "XGQueueController.h"
#import "XGFrameReader.h"

@implementation XGQueueController

-(id)initWitFrameReaderCount:(unsigned)objectCount glContext:(NSOpenGLContext *)context pixelsWide:(unsigned)width pixelsHigh:(unsigned)height
{
    if ((self = [super init])) {
        mFreeQueue = [[D6Queue alloc] init];
        mFilledQueue = [[D6Queue alloc] init];
        
        mFreeQueueMutex = [[NSString alloc] initWithString:@"freeQueueMutex"];
        mFilledQueueMutex = [[NSString alloc] initWithString:@"filledQueueMutex"];
        
        // insert objects to work Q
        unsigned i;
        for (i=0; i<objectCount; i++) {
            XGFrameReader *readerObject = [[XGFrameReader alloc] initWithOpenGLContext:context pixelsWide:width pixelsHigh:height queueController:self];
            if (readerObject) {
                [self addItemToFreeQueue:readerObject];
                [readerObject release];
            }
        }
    }
    
    return self;
}

-(void)addItemToFreeQueue:(id)anItem
{
    @synchronized(mFreeQueueMutex)
    {
        [mFreeQueue insertNewItem:anItem];
    }
}

-(void)addItemToFilledQueue:(id)anItem
{
    @synchronized(mFilledQueueMutex)
    {
        [mFilledQueue insertNewItem:anItem];
    }
}

-(id)removeLastItemFromFreeQueue
{
    id anObject = nil;
    
    @synchronized(mFreeQueueMutex)
    {
        anObject = [mFreeQueue getLastItem];
    }
    
    return anObject;
}

-(id)removeLastItemFromFilledQueue
{
    id anObject = nil;
    
    @synchronized(mFilledQueueMutex)
    {
        anObject = [mFilledQueue getLastItem];
    }
    
    return anObject;
}

- (void) dealloc
{
    if (mFreeQueue)
        [mFreeQueue release];

    if (mFilledQueue)
        [mFilledQueue release];
    
    [mFreeQueueMutex release];
    [mFilledQueueMutex release];
    
    [super dealloc];
    #ifdef __DEBUG_TARGET__
    NSLog(@"XGQueueController Dealloc");
    #endif
}
@end
