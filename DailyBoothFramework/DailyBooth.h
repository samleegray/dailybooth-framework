/*
 *  Cloudie.h
 *  libcurl console tests
 *
 *  Created by Sam Gray on 11/29/10.
 *  Copyright 2010 Sam Gray. All rights reserved.
 *
 */

/* this file is PLAIN C;
 I have it in Objective-C file format so I can uses my Mac/iOS exclusive XMLParser class */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <curl/curl.h>
#include <curl/types.h>
#include <curl/easy.h>

#include "HeaderParser.h"
#import <CommonCrypto/CommonDigest.h>
#import "DailyBoothDelegate.h"
#import "JSON.h"

#define DAILYBOOTH_ROOT_AUTH_URL "https://dailybooth.com/oauth/authorize?"
#define DAILYBOOTH_AUTH_TOKEN "https://dailybooth.com/oauth/token"
#define DAILYBOOTH_ROOT_API "https://api.dailybooth.com/v1"

#define DAILYBOOTH_API_PICTURES "https://api.dailybooth.com/v1/pictures.json"

@interface DailyBooth : NSObject
{
    id<DailyBoothDelegate> delegate;
    HeaderParser *parser;
    int lastPercent;
    NSDictionary *latestJSONDictionary;
@private
	CURL *curl;
	char *stringBuffer;
}

@property(assign, readwrite)id<DailyBoothDelegate> delegate;
@property(assign, readwrite)HeaderParser *parser;
@property(assign, readwrite)int lastPercent;
@property(assign, readwrite)NSDictionary *latestJSONDictionary;

@property(nonatomic, retain)NSString *clientID;
@property(nonatomic, retain)NSString *redirectURI;
@property(nonatomic, retain)NSString *clientSecret;
@property(nonatomic, retain)NSString *oauthToken;

-(id)initWithDelegate:(id <DailyBoothDelegate>)aDelegate;
-(id)initWithOAuthToken:(NSString *)inOAuthToken delegate:(id<DailyBoothDelegate>)aDelegate;
-(id)initWithClientID:(NSString *)inclientID redirectURI:(NSString *)inredirectURI clientSecret:(NSString *)inclientSecret delegate:(id<DailyBoothDelegate>)aDelegate;

-(NSDictionary *)authorize:(NSString *)username password:(NSString *)password;
-(NSDictionary *)oauth_token:(NSString *)code;

-(NSDictionary *)uploadImage:(NSString *)filePathString blurb:(NSString *)blurbString;
-(NSDictionary *)uploadNSImage:(NSImage *)image blurb:(NSString *)blurbString;

-(const char *)convertNSImage:(NSImage *)image;

@end

int uploadProgress(void *blah, double t, double d, double ultotal, double ulnow);
size_t writefunc(void *ptr, size_t size, size_t nmemb, void *s);
size_t writefuncJSON(void *ptr, size_t size, size_t nmemb, void *s);
