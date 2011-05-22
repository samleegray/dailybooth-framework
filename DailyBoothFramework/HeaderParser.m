//
//  HeaderParser.m
//  CloudieApp
//
//  Created by Sam Gray on 2/18/11.
//  Copyright 2011 Sam Gray. All rights reserved.
//

/*Copyright (c) 2011 Samuel Lee Stewart Gray
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE. */

#import "HeaderParser.h"


@implementation HeaderParser

@synthesize headerDictionary;

-(void)startNewParseSet
{
	headerDictionary = nil;
	headerDictionary = [[NSMutableDictionary alloc] init];
}

-(void)parseHeaderString:(NSString *)parseString
{	
	NSString *titleString = [self parseTitleString:parseString];
	NSString *dataString = [self parseDataString:parseString];
	
	if(titleString != nil && dataString != nil)
	{
		[headerDictionary setValue:[self parseDataString:parseString] forKey:[self parseTitleString:parseString]];
	}
}

-(NSString *)parseTitleString:(NSString *)headerString
{
	NSRange parseRange = [headerString rangeOfString:@": "];
	if (parseRange.length != 0) 
	{
		NSString *titleString = [headerString substringWithRange:NSMakeRange(0, parseRange.location)];
		return(titleString);
	}
	
	return(nil);
}

-(NSString *)parseDataString:(NSString *)headerString
{
	NSRange parseRange = [headerString rangeOfString:@": "];
	if (parseRange.length != 0) 
	{
		NSUInteger dataStartLocation = (parseRange.location + parseRange.length);
		NSUInteger dataEndLocation = ([headerString rangeOfString:@"\n" options:NSBackwardsSearch].location - 1);
		NSString *dataString = [headerString substringWithRange:NSMakeRange(dataStartLocation, dataEndLocation - dataStartLocation)];
		return(dataString);
	}
	
	return(nil);
}

-(void)dealloc
{
	[headerDictionary release];
	[super dealloc];
}

@end
