/*
File: FinkTextViewController.m

 See the header file, FinkTextViewController.h, for interface and license information.

*/

#import "FinkTextViewController.h"

@implementation FinkTextViewController

-(id)initWithFrame:(NSRect)frame
{
	if (self = [super initWithFrame:frame]){
		[self setEditable:NO];
	}
	return self;
}

//override parent method
-(void)setString:(NSString *)aString
{
	lines = 0;
	bufferLimit = [[NSUserDefaults standardUserDefaults] integerForKey:FinkBufferLimit];
	minDelete = bufferLimit * 0.10;
	if (minDelete < 10) minDelete = 10;	
	[super setString:aString];
}

-(int)numberOfLinesInString:(NSString *)s
{
 	return [[s componentsSeparatedByString:@"\n"] count] - 1;
}

-(NSRange)rangeOfLinesAtTopOfView:(int)numlines
{
	NSString *viewString = [self string];
	int i, test;
	int lastReturn = 0;
	
	for (i = 0; i < numlines; i++){
		test = 
			[viewString rangeOfString:@"\n"
				options:0
				range:NSMakeRange(lastReturn + 1, 
									[viewString length] - lastReturn - 1)].location;
		if (test == NSNotFound) break;
		lastReturn = test;
	}
	return NSMakeRange(0, lastReturn);
}

-(void)appendString:(NSString *)s
{
	if (bufferLimit > 0){
		int overflow;
		NSRange r;
			
		lines += [self numberOfLinesInString:s];
		overflow = lines - bufferLimit;
		if (overflow > minDelete){
			r = [self rangeOfLinesAtTopOfView:overflow];
			[self replaceCharactersInRange:r withString:@""];
			lines -= overflow;
		}
	}
	[self replaceCharactersInRange:NSMakeRange([[self string] length], 0)
			withString:s];
}


@end
