//
//  main.m
//  xGrab
//
//  Created by Filipe Varela on 07/12/18.
//  Copyright __MyCompanyName__ 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <QuickTime/QuickTime.h>

void ListCompressors(void);

int main(int argc, char *argv[])
{
    // redirect NSLog... Make sure we overwrite
    //id pool = [NSAutoreleasePool new];

    //NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/xGrab.log"];
    //freopen([logPath fileSystemRepresentation], "w", stderr);
    

    //[pool release];
    
    return NSApplicationMain(argc,  (const char **) argv);
}

