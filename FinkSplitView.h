/*
 File: FinkSplitView.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 FinkSplitView is a subclass of NSSplitView that allows the user to collapse 
 or expand the bottom portion of the split view when the divider is double clicked.

 Copyright (C) 2002  Steven J. Burr

 This program is free software; you may redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

 Contact the author at sburrious@users.sourceforge.net.

 */

#import <Cocoa/Cocoa.h>
#import "FinkGlobals.h"

//Used in FinkController and here
#define LS_EXPAND 					\
	NSLocalizedString(@"Show Command Output", @"Menu title when output is collapsed")
#define LS_COLLAPSE 				\
	NSLocalizedString(@"Hide Command Output", @"Menu title when output is expanded")

@interface FinkSplitView : NSSplitView 
{
	NSUserDefaults *defaults;
	NSScrollView *tableScrollView;
	NSScrollView *outputScrollView;
	NSMenuItem *collapseExpandMenuItem;
}

-(void)connectSubviews;
-(void)setCollapseExpandMenuItem:(NSMenuItem *)item;
-(void)collapseOutput:(NSNotification *)n;
-(void)expandOutputToMinimumRatio:(float)r;

@end
