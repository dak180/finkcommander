/*
File: FinkGlobals.m

 See the header file, FinkGlobals.h, for interface and license information.

*/

#import "FinkGlobals.h"

//Global variables used throughout FinkCommander source code to set
//user defaults.
NSString *FinkBasePath = @"FinkBasePath";
NSString *FinkBasePathFound = @"FinkBasePathFound";
NSString *FinkOutputPath = @"FinkOutputPath";
NSString *FinkUpdateWithFink = @"FinkUpdateWithFink";
NSString *FinkAlwaysChooseDefaults = @"FinkAlwaysChooseDefaults";
NSString *FinkScrollToSelection = @"FinkScrollToSelection";
NSString *FinkHTTPProxyVariable = @"FinkHTTPProxyVariable";
NSString *FinkFTPProxyVariable = @"FinkFTPProxyVariable";
NSString *FinkAskForPasswordOnStartup = @"FinkAskForPasswordOnStartup";
NSString *FinkNeverAskForPassword = @"FinkNeverAskForPassword";
NSString *FinkAlwaysScrollToBottom = @"FinkAlwaysScrollToBottom";
NSString *FinkWarnBeforeRunning = @"FinkWarnBeforeRunning";
NSString *FinkWarnBeforeRemoving = @"FinkWarnBeforeRemoving";
NSString *FinkPackagesInTitleBar = @"FinkPackagesInTitleBar";
NSString *FinkAutoExpandOutput = @"FinkAutoExpandOutput";
NSString *FinkGiveEmailCredit = @"FinkGiveEmailCredit";
NSString *FinkCheckForNewVersion = @"FinkCheckForNewVersion";
NSString *FinkBufferLimit = @"FinkBufferLimit";
NSString *FinkLastCheckedForNewVersion = @"FinkLastCheckedForNewVersion";
NSString *FinkCheckForNewVersionInterval = @"FinkCheckForNewVersionInterval";
NSString *FinkEnvironmentSettings = @"FinkEnvironmentSettings";
NSString *FinkInitialEnvironmentHasBeenSet = @"FinkInitialEnvironmentHasBeenSet";

NSString *FinkSelectedColumnIdentifier = @"FinkSelectedColumnIdentifier";
NSString *FinkSelectedPopupMenuTitle = @"FinkSelectedPopupMenuTitle";
NSString *FinkLookedForProxy = @"FinkLookedForProxy";
NSString *FinkOutputViewRatio = @"FinkOutputViewRatio";
NSString *FinkViewMenuSelectionStates = @"FinkViewMenuSelectionStates";
NSString *FinkTableColumnsArray = @"FinkTableColumnsArray";

//Global variables identifying notifications
NSString *FinkConfChangeIsPending = @"FinkConfChangeIsPending";
NSString *FinkRunCommandNotification = @"FinkRunCommandNotification";
NSString *FinkCommandCompleted = @"FinkCommandCompleted";
NSString *FinkPackageArrayIsFinished = @"FinkPackageArrayIsFinished";
NSString *FinkCollapseOutputView = @"FinkCollapseOutputView";

NSString *FinkRunProgressIndicator = @"FinkRunProgressIndicator";

NSString *FinkCreditString = @"&body=%0A%0A--%0AFeedback%20courtesy%20%20of%20FinkCommander";
