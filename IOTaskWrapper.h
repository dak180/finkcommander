/* File:		IOTaskWrapper.h IOTaskWrapperThis is a modified version of TaskWrapper, which can be found as part of theMoriarity sample code at: http://developer.apple.com/samplecode/Sample_Code/Cocoa/Moriarity.htmTaskWrapper is a generalized process handling class that facilitates asynchronousinteraction with an NSTask.  The modifications in IOTaskWrapper allow the user tosend input to the task and to modify the task's environment.  Copyright (C) 2002  Steven J. BurrThis program is free software; you can redistribute it and/or modifyit under the terms of the GNU General Public License as published bythe Free Software Foundation; either version 2 of the License, or(at your option) any later version.This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty ofMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See theGNU General Public License for more details.You should have received a copy of the GNU General Public Licensealong with this program; if not, write to the Free SoftwareFoundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USAContact the author at sburr@mac.com. */#import <Foundation/Foundation.h>@protocol IOTaskWrapperController// Controller's implementation called when output received from NSTask- (void)appendOutput:(NSString *)output;// Intitialization after process starts- (void)processStarted;// Cleanup after process finishes- (void)processFinishedWithStatus:(int)status;@end@interface IOTaskWrapper : NSObject {    NSTask 			*task;    id				<IOTaskWrapperController>controller;    NSArray			*arguments;	NSDictionary	*environment;}// Accessor-(NSTask *)task;// Designated initializer; 1st item in args should be path to command-(id)initWithController:(id <IOTaskWrapperController>)controller    arguments:(NSArray *)args    environment:(NSDictionary *)env;// Launch process, setting up asynchronous feedback notifications.-(void)startProcessWithPassword:(NSData *)pwd;// Write data to process's standard input-(void)writeToStdin: (NSString *)s;// Stop the process and asynchronous feedback notifications.-(void)stopProcess;@end