//
//  D6LicenseValidator.h
//  xGrab
//
//  Created by Filipe Varela on 08/01/03.
//  Copyright 2008 Filipe Varela. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface D6LicenseValidator : NSDocument
{

}

+ (NSString*)checkLicense:(NSData*)licenseData;

@end
