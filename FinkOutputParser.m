/*
File: FinkOutputParser.m

 See the header file, FinkOutputParser.h, for interface and license information.

*/

#import "FinkOutputParser.h"

@implementation FinkOutputParser

//------------------------------------------>Create and Destroy

-(id)initForCommand:(NSString *)cmd
		executable:(NSString *)exe;
{
    if (self = [super init]){
		defaults = [NSUserDefaults standardUserDefaults];
		command = [cmd retain];
		readingPackageList = NO;		
		installing = IS_INSTALL_CMD(command) && [exe contains:@"fink"];
		
		if (installing){
			packageList = [[NSMutableArray alloc] init];
			[packageList addObject:@""];
			increments = [[NSMutableArray alloc] init];
			[self setCurrentPackage:@""];
		}
    }
    return self;
}

-(void)dealloc
{
	[ptracker release];
	[packageList release];
	[increments release];
	[command release];
	[currentPackage release];
	
	[super dealloc];
}

//------------------------------------------>Accessors

-(float)increment{ return increment; }

-(NSString *)currentPackage { return currentPackage; }

-(void)setCurrentPackage:(NSString *)p
{
	[p retain];
    [currentPackage release];
    currentPackage = p;

	Dprintf(@"Setting new current package to %@", currentPackage);
}


//------------------------------------------>Set Up Installation Arrays and Dictionary

//create array of packages to be installed
-(void)addPackagesFromLine:(NSString *)line
{
    [packageList addObjectsFromArray:[[line strip] componentsSeparatedByString:@" "]];
	Dprintf(@"Package list: %@", packageList);
}

//set up array of increments and dictionary of package names matched with
//the increment added so far for that package
-(BOOL)setupInstall
{
    NSEnumerator *e;
    NSString *pname;
    float cumulative[] = {
		0.00,     //NONE
		0.20,     //FETCH 		+ .20
		0.25,     //UNPACK 		+ .05
		0.40,     //CONFIGURE 	+ .15
		0.90,     //COMPILE 	+ .50
		0.95,     //BUILD 		+ .05
		1.00};    //ACTIVATE 	+ .05
    float perpkg = (100.0 - STARTING_INCREMENT) / (float)([packageList count]-1);
    int i;

	if (!packageList){
		NSLog(@"Warning: Empty package list; unable to track installation state");
		return NO;
	}
	 
	e = [packageList objectEnumerator];
    if (! ptracker) ptracker = [[NSMutableDictionary alloc] init];
    while (pname = [e nextObject]){
		[ptracker setObject:[NSNumber numberWithFloat:0.0] forKey:pname];
    }
	
    for (i = 0; i < 7; i++){
		float newincrement = cumulative[i] * perpkg;

		[increments insertObject: [NSNumber numberWithFloat: newincrement]
								  atIndex:i];
		Dprintf(@"increment %d = %f", i, [[increments objectAtIndex:i] floatValue]);
    }
    currentPhase = NONE;
	return YES;
}


//------------------------------------------>Set Package Name and Increment for Phase

//set increment to a level that will bring the progress indicator up to date
//if a previous phase has been skipped (e.g. b/c pkg was already fetched)
-(void)setIncrementForLastPhase
{
    float phaseTotal = [[increments objectAtIndex:currentPhase] floatValue];
	float pkgTotal;
	
	if (!currentPackage || !packageList || !ptracker){
		NSLog(@"Warning:  Data objects for installation tracking were not created");
		return;
	}
	
	if ([currentPackage isEqualToString:@"package"]){
		increment = 0;
		return;
	}else{
		pkgTotal = [[ptracker objectForKey:currentPackage] floatValue];
	}
	
	Dprintf(@"Incrementing for prior phase = %d, package = %@", currentPhase, currentPackage);
	if (phaseTotal > pkgTotal){
		increment = phaseTotal - pkgTotal;
		[ptracker setObject:[NSNumber numberWithFloat:phaseTotal] forKey:currentPackage];
		Dprintf(@"Adding increment: %f - %f = %f", phaseTotal, pkgTotal, increment);
	}else{
		increment = 0;
		Dprintf(@"Old total increment %f >= new total %f; setting increment to 0",
		  pkgTotal, phaseTotal);

	}
}

//find longest name in packageList that matches a string in this line
-(NSString *)packageNameFromLine:(NSString *)line
{
    NSEnumerator *e;
    NSString *candidate;
    NSString *best = @"";
	
	if (!packageList){
		NSLog(@"Warning: No package list created; unable to determine current package");
		return best;
	}
	e = [packageList objectEnumerator];
	//first see if the line contains any of the names in the package list;
	//if so, return the longest name that matches 
    while (candidate = [e nextObject]){
		if ([line containsCI:candidate]){
 			if ([candidate length] > [best length]){
				best = candidate;
			}
		}
    }
	//sometimes the actual file name doesn't include the fink package name,
	//e.g.  <pkg>-ssl is built from <pkg>-<version>.tgz;
	//so parse the line for the file name and look for it in the package name
	if ([best length] < 1 && [line contains:@"-"]){
		NSString *path = [[[[line strip] componentsSeparatedByString:@" "] lastObject] lastPathComponent];
		NSString *chars;
		NSMutableString *fname = [NSMutableString stringWithString:@""];
		NSScanner *lineScanner;
		NSCharacterSet *nums = [NSCharacterSet decimalDigitCharacterSet];
		BOOL foundDash;
		
		Dprintf(@"Failed to find listed package in line:%@", line);
		Dprintf(@"Found full file name+version %@ in line", path);
		lineScanner = [NSScanner scannerWithString:path];
		while (! [lineScanner isAtEnd]){
			foundDash = [lineScanner scanUpToString:@"-" intoString:&chars];
			if  (! foundDash){
				Dprintf(@"Stopped scanning");
				break;
			}
			[fname appendString:chars];
			[lineScanner scanString:@"-" intoString:nil];
			if ([lineScanner scanCharactersFromSet:nums intoString:nil]){
				break;
			}
			[fname appendString:@"-"];
		}
		Dprintf(@"Looking for best match for %@ in:\n%@", fname,
				[packageList componentsJoinedByString:@" "]);
		if ([fname length] > 0){
			NSEnumerator *e = [packageList objectEnumerator];
			while (candidate = [e nextObject]){
				if ([candidate contains:fname]){  //e.g. wget-ssl contains wget
					Dprintf(@"Listed package %@ contains %@", candidate, fname);
					if ([best length] < 1){
						best = candidate;
					}else if ([candidate length] < [best length]){
						best = candidate;
					}
				}
			}
		}
	}
	if ([best length] < 1){
		best = @"package";
	}
    return best;
}


//------------------------------------------>Parse Output

-(int)parseLineOfOutput:(NSString *)line
{
	//Look for package lists
	if (installing && readingPackageList){
		//lines listing pkgs to be installed start with a space
		if ([line hasPrefix:@" "]){
			[self addPackagesFromLine:line];
			return NONE;
		}
		//skip blanks and intro for additional packages
		//continue to scan for package names
		if ([line length] < 1 ||
			[line contains: @"will be installed"]){
			return NONE;
		}
		//not blank, list or intro; done looking for package names
		readingPackageList = NO;
		//if we were unable to create a package list, 
		//turn off installation state signals
		installing = [self setupInstall];
		//look for prompt or installation event immediately after pkg list
		if (ISPROMPT(line)){
			if (installing){
				return PROMPT_AND_START;
			}
			return PROMPT;
		}
		if (installing && FETCHTRIGGER(line)){
			Dprintf(@"Fetch phase triggered by:\n%@", line);
			[self setIncrementForLastPhase];
			[self setCurrentPackage:[self packageNameFromLine:line]];
			currentPhase = FETCH;
			return START_AND_FETCH;
		}
		if (installing && UNPACKTRIGGER(line)){
			Dprintf(@"Unpack phase triggered by:\n%@", line);
			[self setIncrementForLastPhase];
			[self setCurrentPackage:[self packageNameFromLine:line]];
			currentPhase = UNPACK;
			return START_AND_UNPACK;
		}
		if (installing && [line contains: @"dpkg -i"]){
			Dprintf(@"Activate phase triggered by:\n%@", line);
			[self setIncrementForLastPhase];
			[self setCurrentPackage:[self packageNameFromLine:line]];
			currentPhase = ACTIVATE;
			return START_AND_ACTIVATE;			
		}
		//signal FinkController to start deteriminate PI
		return START_INSTALL;
    }
	//Look for introduction to package lists
    if (installing && INSTALLTRIGGER(line)){
		Dprintf(@"Package scan triggered by:\n%@", line);
		readingPackageList = YES;
		return NONE;
    }
	
	//Look for installation events
	if (installing && FETCHTRIGGER(line)){
		Dprintf(@"Fetch phase triggered by:\n%@", line);
		NSString *name = [self packageNameFromLine:line];
		//no action required if retrying failed download
		if ([name isEqualToString:currentPackage]) return NONE;
		[self setIncrementForLastPhase];
		[self setCurrentPackage:name];
		currentPhase = FETCH;
		return FETCH;
    }
    if (installing && (currentPhase != UNPACK) && UNPACKTRIGGER(line)){
		Dprintf(@"Unpack phase triggered by:\n%@", line);
		[self setIncrementForLastPhase];
		[self setCurrentPackage:[self packageNameFromLine:line]];		
		currentPhase = UNPACK;
		return UNPACK;
    }
    if (installing	&& (currentPhase == UNPACK) && CONFIGURETRIGGER(line)){
		Dprintf(@"Configure phase triggered by:\n%@", line);
		[self setIncrementForLastPhase];
		currentPhase = CONFIGURE;
		return CONFIGURE;
    }
    if (installing	&& (currentPhase != COMPILE) && COMPILETRIGGER(line)){
		Dprintf(@"Compile phase triggered by:\n%@", line);
		[self setIncrementForLastPhase];
		currentPhase = COMPILE;
		return COMPILE;
    }
    if (installing && [line contains: @"dpkg-deb -b"]){
		Dprintf(@"Build phase triggered by:\n%@", line);		
		//make sure we catch up if this file is archived
		if (currentPhase < 1) currentPhase = COMPILE;
		[self setIncrementForLastPhase];
		[self setCurrentPackage:[self packageNameFromLine:line]];
		currentPhase = BUILD;
		return BUILD;
    }
    if (installing && [line contains: @"dpkg -i"]){
		Dprintf(@"Activate phase triggered by:\n%@", line);
		if (currentPhase < 1) currentPhase = COMPILE;
		[self setIncrementForLastPhase];
		[self setCurrentPackage:[self packageNameFromLine:line]];
		currentPhase = ACTIVATE;
		return ACTIVATE;
    }	
	
	//Look for password events
	if ([line contains: @"Password:"]){
		return PASSWORD_PROMPT;
    }
	//Look for prompts
    if (ISPROMPT(line) && ! [defaults boolForKey:FinkAlwaysChooseDefaults]){
		Dprintf(@"Found prompt: %@", line);
		return PROMPT;
    } 
	if (ISMANDATORY_PROMPT(line)){
		return MANDATORY_PROMPT;
    }
	if ([line contains:@"Self-repair done"]){
		return SELF_REPAIR;
	} 
	return NONE;
}


-(int)parseOutput:(NSString *)output
{
    NSEnumerator *e = [[output componentsSeparatedByString: @"\n"] objectEnumerator];
    NSString *line;
    int signal = NONE;  //false when used as boolean value

    while (line = [e nextObject]){
		signal = [self parseLineOfOutput:line];
		if (signal) return signal;
    }
    return signal;
}

@end
