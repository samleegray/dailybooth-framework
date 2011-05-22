/*
 *  Cloudie.cpp
 *  libcurl console tests
 *
 *  Created by Sam Gray on 11/29/10.
 *  Copyright 2010 Sam Gray. All rights reserved.
 *
 */

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

#include "DailyBooth.h"

#pragma mark -
#pragma mark libcurl callbacks

int uploadProgress(void *s, double t, /* dltotal */ double d, /* dlnow */ double ultotal, double ulnow)
{
    DailyBooth *dbSelf = (DailyBooth *)s;
    
	int size = 100;
	double fractionDownloaded = ulnow / ultotal;
	int amountFull = round(fractionDownloaded * size);
	
    if(amountFull != [dbSelf lastPercent])
    {
        [[dbSelf delegate] uploadProgress:amountFull];
        [dbSelf setLastPercent:amountFull];
    }
    
	return 0;
}

size_t writefunc(void *ptr, size_t size, size_t nmemb, void *s)
{	
    DailyBooth *dbSelf = (DailyBooth*)s;
    
    NSMutableString *stringToParse = [[NSMutableString alloc] initWithUTF8String:(const char *)ptr];
    int deleteableAmount = [stringToParse length] - nmemb;
    [stringToParse deleteCharactersInRange:NSMakeRange([stringToParse length] - deleteableAmount, deleteableAmount)];

	[[dbSelf parser] parseHeaderString:stringToParse];
	
    [stringToParse release];
	return size*nmemb;
}

size_t writefuncJSON(void *ptr, size_t size, size_t nmemb, void *s)
{
    DailyBooth *dbSelf = (DailyBooth *)s;
    
    NSMutableString *stringToParse = [[NSMutableString alloc] initWithUTF8String:(const char *)ptr];
    int deleteableAmount = [stringToParse length] - nmemb;
    [stringToParse deleteCharactersInRange:NSMakeRange([stringToParse length] - deleteableAmount, deleteableAmount)];
    
    NSDictionary *jsonArray = [stringToParse JSONValue];
    
    if(jsonArray != nil)
    {
        [dbSelf setLatestJSONDictionary:jsonArray];
    }
    
    return size*nmemb;
}

@implementation DailyBooth

@synthesize delegate;
@synthesize parser;
@synthesize lastPercent;
@synthesize latestJSONDictionary;

@synthesize clientID, clientSecret, redirectURI, oauthToken;

-(id)init
{
	self = [super init];
	if (self != nil) 
	{
		stringBuffer = NULL;
		
		curl_global_init(CURL_GLOBAL_ALL);
		curl = curl_easy_init();
		parser = [[HeaderParser alloc] init];
		
		return(self);
	}
	
	return(nil);
}

-(id)initWithDelegate:(id <DailyBoothDelegate>)aDelegate
{
    self = [super init];
    if (self != nil) 
    {
        stringBuffer = NULL;
        curl_global_init(CURL_GLOBAL_ALL);
        curl = curl_easy_init();
        parser = [[HeaderParser alloc] init];
        delegate = aDelegate;
        
        return(self);
    }
    
    return(nil);
}

-(id)initWithOAuthToken:(NSString *)inOAuthToken delegate:(id<DailyBoothDelegate>)aDelegate
{
    self = [super init];
    if(self != nil)
    {
        stringBuffer = NULL;
        curl_global_init(CURL_GLOBAL_ALL);
        curl = curl_easy_init();
        parser = [[HeaderParser alloc] init];
        delegate = aDelegate;
        
        oauthToken = inOAuthToken;
        
        return(self);
    }
    
    return(nil);
}

-(id)initWithClientID:(NSString *)inclientID redirectURI:(NSString *)inredirectURI clientSecret:(NSString *)inclientSecret delegate:(id<DailyBoothDelegate>)aDelegate
{
    self = [super init];
    if(self != nil)
    {
        stringBuffer = NULL;
        curl_global_init(CURL_GLOBAL_ALL);
        curl = curl_easy_init();
        parser = [[HeaderParser alloc] init];
        delegate = aDelegate;
        
        clientID = inclientID;
        redirectURI = inredirectURI;
        clientSecret = inclientSecret;
        
        return(self);
    }
    
    return(nil);
}

-(NSDictionary *)authorize:(NSString *)username password:(NSString *)password
{
    [parser startNewParseSet];
	CURLcode res2;
	
	const char *usernameC = [username UTF8String];
	const char *passwordC = [password UTF8String];
	
	struct curl_httppost *formpost2=NULL;
	struct curl_httppost *lastptr2=NULL;
	struct curl_slist *headerlist2=NULL;
	static const char *buf2 = "Content-Type: multipart/form-data";
	
	curl_formadd(&formpost2, 
				 &lastptr2,
				 CURLFORM_COPYNAME, "username",
				 CURLFORM_COPYCONTENTS, usernameC,
				 CURLFORM_END);
	
	curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "password",
				 CURLFORM_COPYCONTENTS, passwordC,
				 CURLFORM_END);
    
    NSMutableString *authString = [[NSMutableString alloc] initWithString:[NSString stringWithCString:DAILYBOOTH_ROOT_AUTH_URL encoding:NSUTF8StringEncoding]];
    [authString appendFormat:@"client_id=%@&redirect_uri=%@", clientID, redirectURI];
	
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
        curl_easy_reset(curl);
		curl_easy_setopt(curl, CURLOPT_URL, [authString UTF8String]);
		curl_easy_setopt(curl, CURLOPT_HTTPPOST, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)self);
        curl_easy_setopt(curl, CURLOPT_HEADER, 1L);
		
		res2 = curl_easy_perform(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
	
	NSDictionary *headerDictionary = [NSDictionary dictionaryWithDictionary:[parser headerDictionary]];
    
    NSString *location = [[headerDictionary valueForKey:@"Location"] lastPathComponent];
    
    NSArray *firstSplitArray = [location componentsSeparatedByString:@"?"];
    NSArray *secondSplitArray = [[firstSplitArray lastObject] componentsSeparatedByString:@"="];
    
	return([self oauth_token:[secondSplitArray lastObject]]);
}

-(NSDictionary *)oauth_token:(NSString *)code
{
    [parser startNewParseSet];
	CURLcode res2;
	
	struct curl_httppost *formpost2=NULL;
	struct curl_httppost *lastptr2=NULL;
	struct curl_slist *headerlist2=NULL;
	static const char *buf2 = "Content-Type: multipart/form-data";
	
	curl_formadd(&formpost2, 
				 &lastptr2,
				 CURLFORM_COPYNAME, "grant_type",
				 CURLFORM_COPYCONTENTS, "authorization_code",
				 CURLFORM_END);
	
	curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "code",
				 CURLFORM_COPYCONTENTS, [code UTF8String],
				 CURLFORM_END);
    
    curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "client_id",
				 CURLFORM_COPYCONTENTS, [clientID UTF8String],
				 CURLFORM_END);
    
    curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "client_secret",
				 CURLFORM_COPYCONTENTS, [clientSecret UTF8String],
				 CURLFORM_END);
    
    curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "redirect_uri",
				 CURLFORM_COPYCONTENTS, [redirectURI UTF8String],
				 CURLFORM_END);
    
	
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
        curl_easy_reset(curl);
		curl_easy_setopt(curl, CURLOPT_URL, DAILYBOOTH_AUTH_TOKEN);
		curl_easy_setopt(curl, CURLOPT_HTTPPOST, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefuncJSON);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)self);
		
		res2 = curl_easy_perform(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
    
    oauthToken = [latestJSONDictionary valueForKey:@"oauth_token"];
    
	return(latestJSONDictionary);
}

-(NSDictionary *)uploadImage:(NSString *)filePathString blurb:(NSString *)blurbString
{
	[parser startNewParseSet];
	CURLcode res2;
	
	const char *filePath = [filePathString UTF8String];
    const char *blurbC = [blurbString UTF8String];
	
	struct curl_httppost *formpost2=NULL;
	struct curl_httppost *lastptr2=NULL;
	struct curl_slist *headerlist2=NULL;
	static const char buf2[] = "Content-Type: multipart/form-data";
    
    curl_formadd(&formpost2,
                 &lastptr2,
                 CURLFORM_COPYNAME, "oauth_token",
                 CURLFORM_COPYCONTENTS, [oauthToken UTF8String],
                 CURLFORM_END);
    
    curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "picture",
				 CURLFORM_FILE, filePath,
				 CURLFORM_END);
    
    curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "blurb",
				 CURLFORM_COPYCONTENTS, blurbC,
				 CURLFORM_END);
    
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
        curl_easy_reset(curl);
		curl_easy_setopt(curl, CURLOPT_URL, DAILYBOOTH_API_PICTURES);
		curl_easy_setopt(curl, CURLOPT_HTTPPOST, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefuncJSON);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)self);
        curl_easy_setopt(curl, CURLOPT_HEADER, 1L);
		curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0L);
		curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, uploadProgress);
        curl_easy_setopt(curl, CURLOPT_PROGRESSDATA, (void *)self);
		
		res2 = curl_easy_perform(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
    
	return(latestJSONDictionary);
}

-(NSDictionary *)uploadNSImage:(NSImage *)image blurb:(NSString *)blurbString
{
    [parser startNewParseSet];
	CURLcode res2;
    
	const char *filePath = [self convertNSImage:image];
    const char *blurbC = [blurbString UTF8String];
	
	struct curl_httppost *formpost2=NULL;
	struct curl_httppost *lastptr2=NULL;
	struct curl_slist *headerlist2=NULL;
	static const char buf2[] = "Content-Type: multipart/form-data";
	
    curl_formadd(&formpost2,
                 &lastptr2,
                 CURLFORM_COPYNAME, "oauth_token",
                 CURLFORM_COPYCONTENTS, [oauthToken UTF8String],
                 CURLFORM_END);
    
    curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "picture",
				 CURLFORM_FILE, filePath,
				 CURLFORM_END);
    
    curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "blurb",
				 CURLFORM_COPYCONTENTS, blurbC,
				 CURLFORM_END);
    
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
		curl_easy_setopt(curl, CURLOPT_URL, DAILYBOOTH_API_PICTURES);
		curl_easy_setopt(curl, CURLOPT_HTTPPOST, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)self);
        curl_easy_setopt(curl, CURLOPT_HEADER, 1L);
		curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0L);
		curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, uploadProgress);
        curl_easy_setopt(curl, CURLOPT_PROGRESSDATA, (void *)self);
		
		res2 = curl_easy_perform(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
	
	NSDictionary *headerDictionary = [NSDictionary dictionaryWithDictionary:[parser headerDictionary]];
    
	return(headerDictionary);
}

-(const char *)convertNSImage:(NSImage *)image
{
    NSData *data = [[NSBitmapImageRep imageRepWithData:
					 [image TIFFRepresentation]]
					representationUsingType:NSPNGFileType 
					properties:nil];
	NSString *uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
	NSMutableString *uniqueFilename = [NSMutableString stringWithFormat:@"%@.jpg", uniqueString];
	NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:uniqueFilename];
	[data writeToURL:[NSURL fileURLWithPath:filePath] atomically:NO];
    
    [image release];
	
	return([filePath UTF8String]);
}

-(void)dealloc
{
	curl_easy_cleanup(curl);
	curl_global_cleanup();
	[parser release];
	[super dealloc];
}

@end