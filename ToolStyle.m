/* 
   Copyright (C) 1999 Free Software Foundation, Inc.
   
   Written by:	Karl Kraft <karl@nfox.com>
   Date: 		Sep 99
   
   This file is part of nfmake - a utility for building GNUstep programs
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#import <unistd.h>

#import "ToolStyle.h"
#import "NSFileManager_CompareFiles.h"

@implementation ToolStyle
+(BOOL)buildsType:(NSString *)aType;
{
  if ([aType isEqualToString:@"Tool"]) {
    return YES;
  }
  return NO;
}

// unlike all other packages, a tool does not come is a wrapper
- (NSString *)executablePath;
{
  return [[self outputDirectory] stringByAppendingPathComponent:[self projectName]];
}

-(NSString *)resourcePath;
{
  return [[self outputDirectory] stringByAppendingPathComponent:@"Resources"];
}



-(void)linkFinalProduct;
{
  NSTask *aTask = [[[NSTask alloc] init] autorelease];
  NSMutableArray *arguments= [NSMutableArray array];

  if ([[NSFileManager defaultManager] file:[self executablePath] isOlderThanFiles:[self linkables]]==NO) {

//    fprintf(stdout,"up to date\n");
    return;
  }
  fprintf(stdout,"Linking %s\n",[[self executablePath] cString]); fflush(stdout);

  [arguments addObjectsFromArray:[self cFlagArray]];
  [arguments addObject:@"-o"];
  [arguments addObject:[self executablePath]];
  [arguments addObjectsFromArray:[self linkables]];
  [arguments addObject:@"-L/usr/GNUstep/Libraries/machine/"];
  
  [arguments addObject:[NSString stringWithFormat:@"-L%@",[self systemSharedLibraryDirectory]]];

  [arguments addObjectsFromArray:[self executableLinkFlags]];
  [aTask setLaunchPath:@"gcc"];
  [aTask setArguments:arguments];
  [aTask setEnvironment:[self subTaskEnvironment]];
//  fprintf(stdout,"%s\n",[[arguments description] cString]); fflush(stdout);
  [aTask launch];
  sleep (30);
  [aTask waitUntilExit];
  if ([aTask terminationStatus]!=0) {
    fprintf(stderr,"Abort\n");
    exit([aTask terminationStatus]);
  } else {
  }
}

- (NSString *)finalExecutablePath;
{
  return [[self systemExecutableDirectory] stringByAppendingPathComponent:[self projectName]];
}


- (void)installFinalProduct;
{
  NSTask *aTask = [[[NSTask alloc] init] autorelease];
  NSMutableArray *arguments= [NSMutableArray array];
  
  fprintf(stdout,"Installing %s to %s\n",[[self executablePath] cString],[[self systemExecutableDirectory] cString]); fflush(stdout);
  [arguments addObject:@"-D"];
  [arguments addObject:[self executablePath]];
  [arguments addObject:[self systemExecutableDirectory]];
  [aTask setLaunchPath:@"install"];
  [aTask setArguments:arguments];
  [aTask setEnvironment:[self subTaskEnvironment]];
  [aTask launch];
  sleep (30);
  [aTask waitUntilExit];
  if ([aTask terminationStatus]!=0) {
    fprintf(stderr,"Abort\n");
    exit([aTask terminationStatus]);
  } else {
  }
}


- (void)makeTarget:(NSString *)targetName;
{
  if ([targetName isEqualToString:@"InstallHeaders"]) {
    [self installHeaders];
    [self buildSubprojects:targetName];
  } else if ([targetName isEqualToString:@"default"]) {
    [self makeTarget:@"InstallHeaders"];
    [self installResources];
    [self buildSubprojects:targetName];
    [self buildClasses];
    [self linkFinalProduct];
  } else if ([targetName isEqualToString:@"install"]) {
    [self makeTarget:@"default"];
    [self installFinalProduct];
  } else {
    [super makeTarget:targetName];
  }
}


@end
