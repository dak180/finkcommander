/*
File: FinkTableView.m

See the header file, FinkTableView.h, for interface and license information.
*/

#import "FinkTableView.h"

//----------------------------------------------------------
#pragma mark MACROS
//----------------------------------------------------------

//Column widths
#define MAX_FLAG_WIDTH 30.0
#define MAX_STATUS_WIDTH 90.0
#define MAX_CATEGORY_WIDTH 90.0
#define MAX_NAME_WIDTH 200.0
#define MAX_VERSION_WIDTH 130.0

#define IS_VERSION_IDENTIFIER(id) 							\
	[(id) isEqualToString:@"version"]	||					\
	[(id) isEqualToString:@"stable"]	||					\
	[(id) isEqualToString:@"unstable"]	||					\
	[(id) isEqualToString:@"binary"]	||					\
	[(id) isEqualToString:@"installed"]	

@implementation FinkTableView

//----------------------------------------------------------
#pragma mark CREATION AND DESTRUCTION
//----------------------------------------------------------

-(id)initWithFrame:(NSRect)rect
{
	defaults = [NSUserDefaults standardUserDefaults];

	if (self = [super initWithFrame: rect]){
		NSString *identifier;
		NSEnumerator *e = [[defaults objectForKey:FinkTableColumnsArray] objectEnumerator];

		while (nil != (identifier = [e nextObject])){
			[self addTableColumn:[self makeColumnWithName:identifier]];
		}
		[self setDelegate: self];
		[self setDataSource: self];
		[self setAutosaveName: @"FinkTableView"];
		[self setAutosaveTableColumns: YES];
		[self setAllowsMultipleSelection: YES];
		[self setAllowsColumnSelection: NO];
		[self setVerticalMotionCanBeginDrag:NO];
		[self setTarget:self];
		[self setDoubleAction:@selector(openPackageFiles:)];

		[self setLastIdentifier: [defaults objectForKey: FinkSelectedColumnIdentifier]];
		reverseSortImage = [[NSImage imageNamed: @"reverse"] retain];
		normalSortImage = [[NSImage imageNamed: @"normal"] retain];
		// dictionary used to record whether table columns are sorted in normal or reverse order
		columnState = [[defaults objectForKey:FinkColumnStateDictionary] mutableCopy];
	}
	return self;
}

-(void)dealloc
{
	[displayedPackages release];
	[lastIdentifier release];
	[columnState release];
	[reverseSortImage release];
	[normalSortImage release];
	[selectedObjectInfo release];	
	[super dealloc];
}

//----------------------------------------------------------
#pragma mark ACCESSORS
//----------------------------------------------------------

-(NSString *)lastIdentifier {return lastIdentifier;}
-(void)setLastIdentifier:(NSString *)s
{
	[s retain];
	[lastIdentifier release];
	lastIdentifier = s;
}

-(NSArray *)displayedPackages {return displayedPackages;}
-(void)setDisplayedPackages:(NSArray *)a
{
	[a retain];
	[displayedPackages release];
	displayedPackages = a;
}

-(NSArray *)selectedObjectInfo
{
    return selectedObjectInfo;
}

-(void)setSelectedObjectInfo:(NSArray *)array
{
    [array retain];
    [selectedObjectInfo release];
    selectedObjectInfo = array;
}

-(NSImage *)normalSortImage {return normalSortImage;}
-(NSImage *)reverseSortImage {return reverseSortImage;}

-(NSArray *)selectedPackageArray
{
	NSEnumerator *e = [self selectedRowEnumerator];
	NSNumber *anIndex;
	NSMutableArray *pkgArray = [NSMutableArray arrayWithCapacity: 5];

	while (nil != (anIndex = [e nextObject])){
		[pkgArray addObject:
			[[self displayedPackages] objectAtIndex: [anIndex intValue]]];
	}
	return pkgArray;
}

//----------------------------------------------------------
#pragma mark COPY
//----------------------------------------------------------

/* 	Copy the single selected row from the table.  The elements
	are separated by tabs, as text, as well as tabular text 
	(NSTabularTextPboardType). */

-(void)copySelectedRows
{
	NSEnumerator *colEnum = [[self tableColumns] objectEnumerator];
	NSEnumerator *rowEnum = [self selectedRowEnumerator];
	NSMutableString	*theData = [NSMutableString string];
	NSNumber *theRowNum;
	NSTableColumn *theColumn;
	NSPasteboard *pb = [NSPasteboard generalPasteboard];

	// Write the header values
	while (nil != (theColumn = [colEnum nextObject])){
		[theData appendString:[theColumn identifier]];
		[theData appendString:@"\t"];
	}
	[theData appendString:@"\n"];

	while (nil != (theRowNum = [rowEnum nextObject])){
		colEnum = [[self tableColumns] objectEnumerator];

		while (nil != (theColumn = [colEnum nextObject])){
			id columnValue = [self tableView:self objectValueForTableColumn:theColumn
									row:[theRowNum intValue]];
			NSString *columnString = @"";
			if ([columnValue isKindOfClass:[NSImage class]] && nil != columnValue){
				columnString = @"YES";
			}else if (nil != columnValue){
				columnString = [columnValue description];
			}else{
				columnString = @"NO";
			}
			[theData appendFormat:@"%@\t", columnString];
		}
		// delete the last tab.
		if ([theData length]){
			[theData deleteCharactersInRange:NSMakeRange([theData length] - 1, 1)];
		}
		[theData appendString:@"\n"];
	}

	[pb declareTypes: [NSArray arrayWithObjects:NSTabularTextPboardType, NSStringPboardType, nil] owner:nil];
	[pb setString:[NSString stringWithString:theData]
			 forType:NSStringPboardType];
	[pb setString:[NSString stringWithString:theData]
			 forType:NSTabularTextPboardType];
}

-(IBAction)copy:(id)sender
{
	if ([self selectedRow] != -1){
		[self copySelectedRows];
	}
}

//----------------------------------------------------------
#pragma mark FILE DRAG AND DROP
//----------------------------------------------------------

-(BOOL)tableView:(NSTableView *)tview
	writeRows:(NSArray *)rows
	toPasteboard:(NSPasteboard *)pboard
{
	NSArray *fileList = [NSArray array];
    NSEnumerator *e = [rows objectEnumerator];
	NSNumber *rowNum;
	FinkPackage *pkg;
	NSString *tree;
	NSString *path;
	NSFileManager *manager = [NSFileManager defaultManager];

	while (nil != (rowNum = [e nextObject])){
		pkg = [displayedPackages objectAtIndex:[rowNum intValue]];
		if ([[pkg unstable] length] > 1){
			tree = @"unstable";
		}else{
			tree = @"stable";
		}
		path = [pkg pathToPackageInTree:tree
					withExtension:@"patch"];
		if ([manager fileExistsAtPath:path]){
			fileList = [fileList arrayByAddingObject:path];
		}
		path = [pkg pathToPackageInTree:tree
					withExtension:@"info"];
		if ([manager fileExistsAtPath:path]){
			fileList = [fileList arrayByAddingObject:path];
		}		
	}
	[tview registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
	[pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType]
								  owner:self];
	[pboard setPropertyList:fileList forType:NSFilenamesPboardType];
	return YES;
}

- (NSImage *)dragImageForRows:(NSArray*)dragRows 
			event:(NSEvent*)dragEvent 
			dragImageOffset:(NSPointPointer)dragImageOffset
{
	NSImage *dragImage = [NSImage imageNamed:@"info"];

	dragImageOffset->y += [dragImage size].height / 3.5;
	
	return dragImage;
}

-(unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
    return NSDragOperationCopy;
}

//----------------------------------------------------------
#pragma mark ACTION
//----------------------------------------------------------

-(IBAction)openPackageFiles:(id)sender
{
	NSEnumerator *e = [[self selectedPackageArray] objectEnumerator];
	NSMutableArray *problemPaths = [NSMutableArray array];
	NSFileManager *manager = [NSFileManager defaultManager];
	FinkPackage *pkg;
	NSString *extension = ([sender tag] == 0) ? @"info" : @"patch";
	NSString *path, *tree;

	while (nil != (pkg = [e nextObject])){
		tree = ([[pkg unstable] length] > 1) ? @"unstable" : @"stable";
		path = [pkg pathToPackageInTree:tree withExtension:extension];
		if (! [manager fileExistsAtPath:path] || ! openFileAtPath(path)){
			[problemPaths addObject:path];
		}
	}
	alertProblemPaths(problemPaths);
}

//----------------------------------------------------------
#pragma mark COLUMN MANIPULATION
//----------------------------------------------------------

-(NSTableColumn *)makeColumnWithName:(NSString *)identifier
{
	NSTableColumn *newColumn = 
		[[[NSTableColumn alloc] initWithIdentifier:identifier] autorelease];
	NSString *title = [[NSBundle mainBundle] localizedStringForKey:identifier
											 value:identifier
											 table:@"Programmatic"];

	if ([identifier isEqualToString:@"flagged"]){
		NSCell *dataCell = [[NSImageCell alloc] initImageCell:nil];
		[newColumn setDataCell:dataCell];
		[dataCell release];
		[[newColumn headerCell] setImage:[NSImage imageNamed:@"header_flag"]];
		[newColumn setMaxWidth:MAX_FLAG_WIDTH];
	}else{
		[[newColumn headerCell] setStringValue: title];
		[[newColumn headerCell] setAlignment: NSLeftTextAlignment];
		if ([identifier isEqualToString:@"status"]){
			[newColumn setMaxWidth:MAX_STATUS_WIDTH];
		}else if ([identifier isEqualToString:@"category"]){
			[newColumn setMaxWidth:MAX_CATEGORY_WIDTH];
		}else if (IS_VERSION_IDENTIFIER(identifier)){
			[newColumn setMaxWidth:MAX_CATEGORY_WIDTH];
		}
	}
	//Allow double click to open .info file
	if ([identifier isEqualToString:@"name"]){
		[newColumn setEditable:NO];
	}else{
		[newColumn setEditable:YES];
	}
	return newColumn;
}

//Sent by View menu action method
-(void)addColumnWithName:(NSString *)identifier
{
	NSArray *columnNames = [defaults objectForKey: FinkTableColumnsArray];
	NSTableColumn *newColumn = [self makeColumnWithName: identifier];
	NSTableColumn *lastColumn = [[self tableColumns] lastObject];
	NSRect oldFrame = [[self window] frame];
	NSRect newFrame = NSMakeRect(oldFrame.origin.x, oldFrame.origin.y,
		oldFrame.size.width + 2, oldFrame.size.height);
		
	[newColumn setWidth: MIN([newColumn maxWidth], [lastColumn width] *0.5)];
	[lastColumn setWidth: MIN([lastColumn maxWidth], 
							  [lastColumn width] - [newColumn width])];

	[self addTableColumn: newColumn];
	[[self window] setFrame:newFrame display:YES];
	[self sizeLastColumnToFit];

	columnNames = [columnNames arrayByAddingObject: identifier];
	[defaults setObject: columnNames forKey: FinkTableColumnsArray];
}

-(void)removeColumnWithName:(NSString *)identifier
{	
	NSArray *columns = [defaults objectForKey: FinkTableColumnsArray];
	NSMutableArray *reducedColumns = [[columns mutableCopy] autorelease];
	
	[self removeTableColumn: [self tableColumnWithIdentifier: identifier]];
	[self sizeLastColumnToFit];
	[reducedColumns removeObject: identifier];
	columns = reducedColumns;
	[defaults setObject:columns forKey:FinkTableColumnsArray];
}

//----------------------------------------------------------
#pragma mark DATA SOURCE METHODS
//----------------------------------------------------------

-(int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[self displayedPackages] count];
}

-(id)tableView:(NSTableView *)aTableView
	objectValueForTableColumn:(NSTableColumn *)aTableColumn
	row:(int)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	FinkPackage *package = [[self displayedPackages] objectAtIndex:rowIndex];
	if ([identifier isEqualToString:@"status"]){
		NSString *pkgStatus = [package status];
		return [[NSBundle mainBundle] localizedStringForKey:pkgStatus
									  value:pkgStatus
									  table:@"Programmatic"];
	}
	if ([identifier isEqualToString:@"flagged"]){
		int flag = [[package valueForKey:identifier] intValue];
		if (flag == 1) return [NSImage imageNamed:@"flag"];
		return nil;
	}
	return [package valueForKey:identifier];
}

//----------------------------------------------------------
#pragma mark SORTING
//----------------------------------------------------------

/* 	The following two methods are used to scroll back to the previously selected row
	after the table is sorted.  It works almost the same way Mail does, except
	that only the latest selection is preserved.  For the filter, sorting and
	scrolling methods to work together, information on the selected object must
	be stored and then the rows must be deselected before the filter is applied
	and before the table is sorted. */

//Store information needed to scroll back to selection after filter/sort
-(void)storeSelectedObjectInfo
{
	FinkPackage *selectedObject;
    int selectionIndex = [self selectedRow];
	int topRowIndex =  [self rowAtPoint:
		[[self superview] bounds].origin];
	int offset = selectionIndex - topRowIndex;

	if (selectionIndex >= 0){
		selectedObject = [[self displayedPackages]
							objectAtIndex: selectionIndex];
		[self setSelectedObjectInfo:
			[NSArray arrayWithObjects:
				selectedObject,
				[NSNumber numberWithInt: offset],
				nil]];
		[self deselectAll: nil];
	}else{
		[self setSelectedObjectInfo: nil];
	}
}

//Scroll back to selection after sort
-(void)scrollToSelectedObject
{
	if ([self selectedObjectInfo]){
		FinkPackage *selectedObject = [[self selectedObjectInfo] objectAtIndex: 0];
		int selection = [[self displayedPackages] indexOfObject: selectedObject];

		if (selection != NSNotFound){
			int offset = [[[self selectedObjectInfo] objectAtIndex: 1] intValue];
			NSPoint offsetRowOrigin = [self rectOfRow: selection - offset].origin;
			id contentView = [self superview];
			id tableScrollView = [contentView superview];
			NSPoint target = [contentView constrainScrollPoint: offsetRowOrigin];

			[contentView scrollToPoint: target];
			[tableScrollView reflectScrolledClipView: contentView];
			[self selectRow: selection byExtendingSelection: NO];
		}
	}
}

//Basic sorting method
-(void)sortTableAtColumn:(NSTableColumn *)aTableColumn inDirection:(NSString *)direction
{
	NSArray *newArray = 
		[[self displayedPackages] sortedArrayUsingSelector:
			NSSelectorFromString([NSString stringWithFormat: @"%@CompareBy%@:", direction,
			[[aTableColumn identifier] capitalizedString]])]; // e.g. reverseCompareByName:
	[self setDisplayedPackages:newArray];
	[self reloadData];
}

//Sent by delegate method for filter text view in FinkController
-(void)resortTableAfterFilter
{
	NSTableColumn *lastColumn = [self tableColumnWithIdentifier:
		[self lastIdentifier]];
	NSString *direction = [columnState objectForKey: [self lastIdentifier]];

	[self sortTableAtColumn: lastColumn inDirection: direction];
}


//----------------------------------------------------------
#pragma mark DELEGATE METHODS
//----------------------------------------------------------

-(void)tableView:(NSTableView *)aTableView
	didClickTableColumn:(NSTableColumn *)aTableColumn
{
	NSString *identifier = [aTableColumn identifier];
	NSTableColumn *lastColumn = [self tableColumnWithIdentifier:
		[self lastIdentifier]];
	NSString *direction;

	// remove sort direction indicator from last selected column
	[self setIndicatorImage: nil inTableColumn: lastColumn];

	// if user clicks same column header twice in a row, change sort order
	if ([aTableColumn isEqualTo: lastColumn]){
		direction = [[columnState objectForKey: identifier] isEqualToString: @"normal"]
						? @"reverse" : @"normal";
		//record new state for next click on this column
		[columnState setObject: direction forKey: identifier];
		[defaults setObject:[[columnState copy] autorelease]
				  forKey:FinkColumnStateDictionary];
		// otherwise, return sort order to previous state for selected column
	}else{
		direction = [columnState objectForKey: identifier];
	}

	// record currently selected column's identifier for next call to method
	// and for future sessions
	[self setLastIdentifier: identifier];
	[defaults setObject: identifier forKey: FinkSelectedColumnIdentifier];

	// reset visual indicators
	if ([direction isEqualToString: @"reverse"]){
		[self setIndicatorImage: reverseSortImage
							 inTableColumn: aTableColumn];
	}else{
		[self setIndicatorImage: normalSortImage
							 inTableColumn: aTableColumn];
	}
	[self setHighlightedTableColumn: aTableColumn];

	// sort the table contents
	if ([defaults boolForKey: FinkScrollToSelection]){
		[self storeSelectedObjectInfo];
	}
	[self sortTableAtColumn: aTableColumn inDirection: direction];
	if ([defaults boolForKey: FinkScrollToSelection]){
		[self scrollToSelectedObject];
	}
}

-(BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	NSString *pname = [[[self displayedPackages] objectAtIndex: rowIndex] name];
	if ([pname contains:@"tcsh"] 				|| 
		[pname contains:@"term-readkey-pm"]){
		NSBeginAlertSheet(LS_WARNING,
					LS_OK,
					nil, nil,
					[self window], self, NULL,	NULL, nil,
					[NSString stringWithFormat:NSLocalizedString(@"FinkCommander is unable to install %@ from source.  Please install the binary or use the Source:Run in Terminal menu command to install %@.", @"Alert sheet message"), pname, pname],
					nil);
	}
	return YES;
}

-(BOOL)textShouldBeginEditing:(NSText *)textObject
{
	return NO;
}

@end
 