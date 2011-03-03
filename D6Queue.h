//
//  D6Queue.h
//  xGrab
//
//  Created by Filipe Varela on 07/12/18.
//  Copyright 2007 Filipe Varela. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface D6Queue : NSObject {
    NSMutableArray *mQueueItemArray;
}

-(id)getLastItem;
-(void)insertNewItem:(id)anItem;
-(int)count;

@end
