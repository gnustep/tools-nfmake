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

/*
 *  A tool style is used for building command line tools
 *  
 *  Example build tree
 *  
 *  ls
 *  Resources/ls/
 *  Resource/ls/ls.help
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
// IMHO - it should
- (NSString *)executablePath;
{
  return [[self outputDirectory] stringByAppendingPathComponent:[self projectName]];
}


// We place tool 
-(NSString *)resourcePath;
{
  NSString *tmpString = [self outputDirectory];
  tmpString=[tmpString stringByAppendingPathComponent:@"Resources"];
  tmpString=[tmpString stringByAppendingPathComponent:[self projectName]];
  return tmpString;
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
  [arguments addObjectsFromArray:[self libraryDirectoryFlags]];
  [arguments addObjectsFromArray:[self executableLinkFlags]];
  [aTask setLaunchPath:@"gcc"];
  [aTask setArguments:arguments];
  [aTask setEnvironment:[self subTaskEnvironment]];
//  fprintf(stdout,"%s\n",[[arguments description] cString]); fflush(stdout);
  [aTask launch];
  //sleep (30);
  [aTask waitUntilExit];
  if ([aTask terminationStatus]!=0) {
    fprintf(stderr,"Abort\n");
    exit([aTask terminationStatus]);
  } else {
  }
}

- (NSString *) installDirectory;
{
  NSString *aString = [super installDirectory];
  if (aString) return aString;
  // TODO - get from environment
  return @"/usr/GNUstep/Local/Tools";
}

- (NSString *)installedExecutablePath;
{
  return [[self installDirectory] stringByAppendingPathComponent:[self projectName]];
}

- (NSString *)installedResourceDirectory;
{
  NSString *aString=[self installDirectory];
  aString=[aString stringByAppendingPathComponent:@"Resources"];
  return aString;
  
}


- (NSString *)installedResourcePath;
{
  NSString *aString=[self installedResourceDirectory];
  aString=[aString stringByAppendingPathComponent:[self projectName]];
  return aString;
  
}

- (void)installFinalProduct;
{
  NSFileManager *theMan=[NSFileManager defaultManager];


  // fprintf(stdout,"Installing %s\n",[[self installedExecutablePath] cString]);
  [theMan installFromPath:[self executablePath] 
                    toDir:[self installDirectory] 
        operationDelegate:[self copyDelegate]];

  //fprintf(stdout,"Installing %s\n",[[self installedResourcePath] cString]);
  [theMan installFromPath:[self resourcePath] 
                    toDir:[self installedResourceDirectory] 
        operationDelegate:[self copyDelegate]];

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
