/*
 File: FinkPackageInfo.m

 See the header file, FinkPackageInfo.h, for interface and license information.

*/

#import "FinkPackageInfo.h"
#import "SBMutableAttributedString.h"

//medium gray
#define SHORTDESCCOLOR 		\
	[NSColor colorWithCalibratedHue:0.0 saturation:0.0 brightness:0.50 alpha:1.0]
//medium gray
#define VERSIONCOLOR 		\
	[NSColor colorWithCalibratedHue:0.0 saturation:0.0 brightness:0.40 alpha:1.0]
//dark green
#define URLCOLOR 			\
	[NSColor colorWithCalibratedHue:0.33 saturation:1.0 brightness:0.60 alpha:1.0]
//dark blue
#define HEADINGCOLOR 		\
	[NSColor colorWithCalibratedHue:0.67 saturation:1.0 brightness:0.60 alpha:1.0]

#define MAINHEADINGFONT [NSFont boldSystemFontOfSize:[NSFont systemFontSize]+2.0]

@implementation FinkPackageInfo

-(id)init
{
	self = [super initWithWindowNibName:@"PackageInfo"];
	defaults = [NSUserDefaults standardUserDefaults];
	[self setWindowFrameAutosaveName: @"PackageInfo"];
	[[self window] setTitle:NSLocalizedString(@"Package Info", nil)];
	[self setEmailSig:@""];

	return self;
}

-(void)awakeFromNib
{
	textView = [MyTextView myTextViewToReplace:textView in:scrollView];
	[[textView window] setDelegate: self];
}

-(void)dealloc
{
	[emailSig release];
	[super dealloc];
}


//--------------------------------------------------------------->Email Methods

-(void)setEmailSig:(NSString *)s
{
	[s retain];
	[emailSig release];
	emailSig = s;
}

//used to set URL attribute for email addresses displayed by Package Inspector and
//in FinkController's emailMaintainer method
-(NSURL *)mailURLForPackage:(FinkPackage *)pkg
{ 
	return [[NSString stringWithFormat: 
						@"mailto:%@?subject=%@-%@&body=\n\n%@", 
						[pkg email], [pkg name], [pkg version], emailSig]
				URLByAddingPercentEscapesToString];
}

//--------------------------------------------------------------->Text Display Methods

//Add font attributes to headings and link attributes to urls; remove hard returns
//within paragraphs to allow soft wrapping; attempt to preserve author's list formatting
-(NSAttributedString *)formattedDescriptionString:(NSString *)s //<--why?
						forPackage:(FinkPackage *)p
{
	NSEnumerator *e = [[s componentsSeparatedByString: @"\n"] objectEnumerator];
	NSEnumerator *f = [[NSArray arrayWithObjects: @"Summary", @"Description",
								@"Usage Notes", @"Web site", @"Maintainer", nil] 
							objectEnumerator];
	NSDictionary *urlAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									URLCOLOR, NSForegroundColorAttributeName,
									[NSNumber numberWithInt: NSSingleUnderlineStyle],
											NSUnderlineStyleAttributeName,
									nil];
	NSMutableAttributedString *desc = 	
			[[[NSMutableAttributedString alloc]
					initWithString: @""
						   attributes: [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSFont systemFontOfSize:0], NSFontAttributeName,
							   nil]] autorelease];
	NSString *line;
	NSString *field;
	NSRange r;	      //general purpose range variable
	
	[e nextObject];   //discard summary; already included
	//test second line for period or DescDetail
	line = [[e nextObject]  strip];
	if (! line) return desc;
	if ([line isEqualToString: @"."]){ 		//change period to 2 newlines
		[desc appendString: @"\n\n"];
	}else{									//add newlines before DescDetail
		[desc appendString:[NSString stringWithFormat: @"\n\n%@ ", line]];
	}

	while (nil != (line = [e nextObject])){
		//remove linefeed within paragraphs to allow wrapping in text view
		line = [line strip];
		/* 	In fink descriptions, paragraph breaks are signified by a period. 
			At least one package description separates sections by double
			periods. */
		if ([line containsExpression: @"^[.]+$"]){
			if ([[desc string] hasSuffix:@"\n"]){
				line = @"\n";
			}else{
				line = @"\n\n";
			}
		//If line begins with punctuation intended as a bullet, put the linefeed back
		}else if ([line hasPrefix:@"-"] 	|| 
				  [line hasPrefix:@"*"] 	|| 
				  [line hasPrefix:@"o "]){
			line = [NSString stringWithFormat: @"%@\n", line];
			if (! [[desc string] hasSuffix: @"\n"]){
				line = [NSString stringWithFormat: @"\n%@", line];
			}
		}else{
			line = [NSString stringWithFormat: @"%@ ", line]; 
		}
		[desc appendString:line];
	}
	
	//apply attributes to field names
	while (field = [f nextObject]){
		r = [[desc string] rangeOfString: field];
		if (r.length > 0){
			[desc addAttribute: NSForegroundColorAttributeName 
				  value: HEADINGCOLOR 
				  range: r];
		}
	}
	
	//look for web url and if found turn it into an active link
	if ([[p weburl] length] > 0){
		r = [[desc string] rangeOfString: [p weburl]];
		[desc addAttributes: urlAttributes range: r];
		[desc addAttribute: NSLinkAttributeName
							value: [NSURL URLWithString: [p weburl]]
							range: r];
	}
		
	//look for e-mail url and if found turn it into an active link
	if ([[p email] length] > 0){
		NSURL *murl = [self mailURLForPackage:p];
		r = [[desc string] rangeOfString:[p email]];
		[desc addAttributes:urlAttributes range:r];
		[desc addAttribute:NSLinkAttributeName
				value:murl
				range:r];
	}
	return desc;
}

//Add font attributes, spacing and newlines for various versions of package
-(NSAttributedString *)formattedVersionsForPackage:(FinkPackage *)pkg
{
	NSEnumerator *e = [[NSArray arrayWithObjects: @"Installed", @"Unstable", @"Stable",
		@"Binary", nil] objectEnumerator];
	NSString *vName;
	NSString *vNumber;
	NSMutableAttributedString *desc =
		[[[NSMutableAttributedString alloc]
				initWithString: @""
				attributes: [NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:0]
										  forKey:NSFontAttributeName]] 
								autorelease];
	
	while (nil != (vName = [e nextObject])){
		vNumber = [pkg performSelector:NSSelectorFromString([vName lowercaseString])];
		if ([vNumber length] < 2) vNumber = @"None";
		if ([vName length] < 8) vNumber = [NSString stringWithFormat: @"\t%@", vNumber];
		[desc appendAttributedString:
			[[[NSMutableAttributedString alloc]
					initWithString: [NSString stringWithFormat: @"\n%@:", vName]
					attributes:[NSDictionary dictionaryWithObjectsAndKeys:
									[NSFont systemFontOfSize:0], NSFontAttributeName,
									HEADINGCOLOR, NSForegroundColorAttributeName,
									nil]]
								autorelease]];
		[desc appendAttributedString:
			[[[NSMutableAttributedString alloc]
				initWithString: [NSString stringWithFormat: @"\t%@", vNumber]
					attributes:[NSDictionary dictionaryWithObjectsAndKeys:
									[NSFont systemFontOfSize:0], NSFontAttributeName,
									VERSIONCOLOR, NSForegroundColorAttributeName,
									nil]] 
								autorelease]];
	}	
	return desc;
}

-(void)displayDescriptions:(NSArray *)packages
{
	int i, count = [packages count];
	FinkPackage *pkg;
	NSString *pname;
	NSString *psummary;

	[[textView textStorage] beginEditing];

	[textView setString: @""];
	for (i = 0; i < count; i++){
		pkg = [packages objectAtIndex: i];
		pname = [NSString stringWithFormat:@"%@\n", [pkg name]];
		psummary = [NSString stringWithFormat:@"%@\n", [pkg summary]];
		[[textView textStorage] appendAttributedString:
			[[[NSAttributedString alloc] 
					initWithString: pname
					attributes: [NSDictionary dictionaryWithObjectsAndKeys: 
										MAINHEADINGFONT, NSFontAttributeName,
										HEADINGCOLOR, NSForegroundColorAttributeName,
										nil]] autorelease]];
		[[textView textStorage] appendAttributedString:
			[[[NSAttributedString alloc]
					initWithString: psummary
						attributes: [NSDictionary dictionaryWithObjectsAndKeys:
										[NSFont systemFontOfSize:0], NSFontAttributeName,
										SHORTDESCCOLOR, NSForegroundColorAttributeName,
										nil]] autorelease]];
		[[textView textStorage] appendAttributedString:
			[self formattedVersionsForPackage:pkg]];
		[[textView textStorage] appendAttributedString:
			[self formattedDescriptionString: [pkg fulldesc] forPackage: pkg]];
		if (i != count - 1){  			//just add one newline after last package
			[[textView textStorage] appendString:@"\n\n\n"];
		}else{
			[[textView textStorage] appendString:@"\n"];
		}
	}
	
	[[textView textStorage] endEditing];
}


//--------------------------------------------------------------->NSWindow Delegate Methods

//Resize window when zoom button clicked
-(NSRect)windowWillUseStandardFrame:(NSWindow *)sender
		 defaultFrame:(NSRect)defaultFrame
{	
	float windowOffset = [[self window] frame].size.height 
							- [[textView superview] frame].size.height;
	float newHeight = [textView frame].size.height;	
	NSRect stdFrame = 
		[NSWindow contentRectForFrameRect:[sender frame] 
							 styleMask:[sender styleMask]];

	if (newHeight > stdFrame.size.height) {newHeight += windowOffset;}
							 
	stdFrame.origin.y += stdFrame.size.height;
	stdFrame.origin.y -= newHeight;
	stdFrame.size.height = newHeight;

	stdFrame = 
		[NSWindow frameRectForContentRect:stdFrame 
							 styleMask:[sender styleMask]];
							 
	//if new height would exceed default frame height,
	//zoom vertically and horizontally
	if (stdFrame.size.height > defaultFrame.size.height){
		stdFrame = defaultFrame;
	//otherwise zoom vertically just enough to accomodate new height
	}else if (stdFrame.origin.y < defaultFrame.origin.y){
		stdFrame.origin.y = defaultFrame.origin.y;
	}

	return stdFrame;
}

//Prevent last selection from appearing when panel reopens
-(void)windowWillClose:(NSNotification *)n
{
	[textView setString: @""];  
}

@end
