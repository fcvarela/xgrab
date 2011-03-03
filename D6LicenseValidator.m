//
//  D6LicenseValidator.m
//  xGrab
//
//  Created by Filipe Varela on 08/01/03.
//  Copyright 2008 Filipe Varela. All rights reserved.
//

#import "D6LicenseValidator.h"
#import "AquaticPrime.h"

@implementation D6LicenseValidator

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.
    if ([D6LicenseValidator checkLicense: data] == nil) {
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
            NSLocalizedStringFromTable(@"RegistrationError",@"Localizations",nil),NSLocalizedDescriptionKey,
            NSLocalizedStringFromTable(@"RegistrationErrorReason",@"Localizations",nil),NSLocalizedFailureReasonErrorKey,
            nil];
        *outError = [NSError errorWithDomain:@"com.dev6.xGrab" code:-1 userInfo: errorDict];
        return NO;
    }
    
    // got here? valid license. just copy to ~/Preferences/com.dev6.xgrab.xgrablicense
    [data writeToFile:[@"~/Library/Preferences/com.dev6.xGrab.xgrablicense" stringByExpandingTildeInPath] atomically:YES];
    
    // notify the app's delegate (XGMainController) that we're registered
    id appDelegate = [[NSApplication sharedApplication] delegate];
    [appDelegate performSelector:@selector(setRegistered)];
    return YES;
}

- (void)dealloc
{
    [super dealloc];
}

+ (NSString*)checkLicense:(NSData*)licenseData
{
	NSMutableString *key = [NSMutableString string];
	[key appendString:@"0xCE9D53E6C510FD0"];
	[key appendString:@"F"];
	[key appendString:@"F"];
	[key appendString:@"00D57764DA1"];
	[key appendString:@"63691A1E4642362C84A9A48139C857"];
	[key appendString:@""];
	[key appendString:@"A"];
	[key appendString:@"A"];
	[key appendString:@"A7DBB84DD24F203BD2302A3AF4E5"];
	[key appendString:@"8E"];
	[key appendString:@"7"];
	[key appendString:@"7"];
	[key appendString:@"8FA89F4BD1059E50D0A1B61CAC"];
	[key appendString:@"6C29A431CD5DB"];
	[key appendString:@"E"];
	[key appendString:@"E"];
	[key appendString:@"413B0D2E78C5DA5"];
	[key appendString:@"24A0"];
	[key appendString:@"F"];
	[key appendString:@"F"];
	[key appendString:@"EE625FCC847C359965D7BC02"];
	[key appendString:@"109D9BE0A71784B3FD8ED8"];
	[key appendString:@"D"];
	[key appendString:@"D"];
	[key appendString:@"DB19EE"];
	[key appendString:@"B7C27CFD9F9F5B"];
	[key appendString:@"0"];
	[key appendString:@"0"];
	[key appendString:@"D1011319E489EA"];
	[key appendString:@"09773B6DD8E271112F"];

    // Instantiate AquaticPrime
    AquaticPrime *licenseValidator = [AquaticPrime aquaticPrimeWithKey:key];
    
    // Blacklist bad licenses
    //[licenseValidator setBlacklist:[NSArray arrayWithObject:@"d7176e066b79d1cff0e0792532157fd3641a9b93"]];

    // Get the dictionary from the license file
    // If the license is invalid, we get nil back instead of a dictionary
    NSDictionary *licenseDictionary = [licenseValidator dictionaryForLicenseData:licenseData];
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    if (licenseDictionary == nil) {
        [def setObject: @"Unregistered" forKey:@"registrationName"];
        [def setObject: @"unregistered@unregistered.com" forKey:@"registrationEmail"];
        return nil;
    }
    else {
        // set defaults
        [def setObject: [licenseDictionary objectForKey:@"Name"] forKey:@"registrationName"];
        [def setObject: [licenseDictionary objectForKey:@"Email"] forKey:@"registrationEmail"];
        return [licenseDictionary objectForKey:@"Name"];
    }
}

@end
