/*
 File:		IOTaskWrapper.m
 
 See the header file, IOTaskWrapper.h, for interface and license information.

 */

#import "IOTaskWrapper.h"

@implementation IOTaskWrapper

-(id)initWithController:(id <IOTaskWrapperController>)cont
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *basePath = [defaults objectForKey: FinkBasePath];

    if (self = [super init]){
		controller = cont;
		binPath = [[NSString alloc] initWithString: [basePath
						  stringByAppendingPathComponent: @"/bin"]];
		environment = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSString stringWithFormat:
			    @"/%@:/%@/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:",
				binPath, basePath],
			@"PATH",
			[NSString stringWithFormat: @"%@/lib/perl5", basePath],
			@"PERL5LIB",
			nil];
		task = [[NSTask alloc] init];
	}
    return self;
}

-(void)dealloc
{
    [self stopProcess];

	[environment release];
	[password release];
    [task release];
    [super dealloc];
}

-(NSTask *)task
{
	return task;
}

-(void)setPassword:(NSData *)p{
	[p retain];
	[password release];
	password = p;
}

// Start the process via an NSTask.
-(void)startProcessWithArgs: (NSMutableArray *)arguments
{
	[controller processStarted];

    [task setStandardOutput: [NSPipe pipe]];
    [task setStandardError: [task standardOutput]];
	[task setStandardInput: [NSPipe pipe]];	
    [task setLaunchPath: @"/usr/bin/sudo"];

	[arguments insertObject: @"-S" atIndex: 0];
	if ([[arguments objectAtIndex: 1] isEqualToString: @"fink"] &&
	    [[NSUserDefaults standardUserDefaults] boolForKey: FinkAlwaysChooseDefaults]){
		[arguments insertObject: @"-y" atIndex: 2];
	}
    [task setArguments: arguments];
	[task setEnvironment: environment];

    [[NSNotificationCenter defaultCenter] addObserver:self 
        selector:@selector(getData:) 
        name: NSFileHandleReadCompletionNotification 
        object: [[task standardOutput] fileHandleForReading]];

    [[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];

    // launch the task asynchronously
    [task launch];

//	[[[task standardInput] fileHandleForWriting] writeData: password];
}


-(void)stopProcess
{
	// Make sure task is really finished before calling processFinishedWithStatus.
	// Otherwise sending terminationStatus message to task will raise error.
	// Experimented with terminate and interrupt methods; didn't work in this context
	while ([task isRunning]){
		continue;
	}
	
	[controller processFinishedWithStatus: [task terminationStatus]];    
    controller = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
	  name: NSFileHandleReadCompletionNotification object: [[task standardOutput] fileHandleForReading]];
    
    // Probably superfluous given change made above
    //[task terminate];
}

// Get data asynchronously from process's standard output
-(void)getData: (NSNotification *)aNotification
{
    NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];

    if ([data length]){
        [controller appendOutput: [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];
    } else {
        [self stopProcess];
    }
    
    // need to schedule the file handle go read more data in the background again.
    [[aNotification object] readInBackgroundAndNotify];
}

// ADDED: Write data to process's standard input
-(void)writeToStdin: (NSString *)s
{
	[[[task standardInput] fileHandleForWriting] writeData:
		[NSData dataWithData: [s dataUsingEncoding: NSUTF8StringEncoding]]];
}

@end

