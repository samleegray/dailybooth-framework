This is licensed with the MIT license. The full license information can be found in LICENSE.txt.

Example code:

	DailyBooth *tg = [[DailyBooth alloc] initWithClientID:@"your client id" redirectURI:@"your uri" clientSecret:@"your client secret" delegate:self];

	NSDictionary *oauth_token = nil;
	oauth_token = [tg authorize:@"username" password:@"password"];

	NSLog(@"oauth_token:%@\n", [oauth_token valueForKey:@"oauth_token"]);

	NSDictionary *dict = [tg uploadImage:@"urltoimage.imageext" blurb:@"testing! :D"];

	NSLog(@"dict:%@\n", [[dict valueForKey:@"user"] valueForKey:@"username"]);

	[tg release];