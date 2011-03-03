//
//  D6Queue.m
//  xGrab
//
//  Created by Filipe Varela on 07/12/18.
//  Copyright 2007 Filipe Varela. All rights reserved.
//

#import "D6Queue.h"

@implementation D6Queue

- (id) init
{
    
    self = [super init];
    {
        mQueueItemArray = [NSMutableArray arrayWithCapacity: 0];
        [mQueueItemArray retain];
    }
    
    return self;
}

- (id) getLastItem
{
    id returnObject = nil;
    
    returnObject = [mQueueItemArray lastObject];
    if (returnObject) {
        [returnObject retain]; // bad bad bad... (fixex in return autorelease)
        [mQueueItemArray removeLastObject];
    }
    
    return [returnObject autorelease];;
}

- (void) insertNewItem:(id)anItem
{
    [mQueueItemArray insertObject: anItem atIndex: 0];
}

- (int) count
{
    return [mQueueItemArray count];
}

- (void) dealloc
{
    //[mQueueItemArray removeLastObject];
    [mQueueItemArray release];
    [super dealloc];
    #ifdef __DEBUG_TARGET__
        NSLog(@"D6Queue Dealloc");
    #endif
}

@end
