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

#import "ApplicationStyle.h"
#import <unistd.h>

@implementation ApplicationStyle
+(BOOL)buildsType:(NSString *)aType;
{
  if ([aType isEqualToString:@"Application"]) {
    return YES;
  }
  return NO;
}

- (NSString *)componentPath;
{
    return [NSString stringWithFormat:@"%@/%@.app",
             [self outputDirectory],
             [self projectName]];
             }


-(void)linkFinalProduct;
{
  NSTask *aTask = [[[NSTask alloc] init] autorelease];
  NSMutableArray *arguments= [NSMutableArray array];

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
//  NSLog(@"%@",arguments);
  [aTask launch];
  sleep(30);
  [aTask waitUntilExit];
  if ([aTask terminationStatus]!=0) {
    fprintf(stderr,"Abort\n");
    exit([aTask terminationStatus]);
  } else {
  }
}

- (NSString *)applicationClass;
{
	NSString *s=[initialDictionary objectForKey:@"APPCLASS"];
	if (s) return s;
	return @"NSApplication";
}

- (NSString *)mainNibFile;
{
	NSString *s=[initialDictionary objectForKey:@"MAINNIB"];
	if (s) return s;
    return [NSString stringWithFormat:@"%@.nib",
             [self projectName]];
}

- (NSString *)appIcon;
{
	NSString *s=[initialDictionary objectForKey:@"APPICON"];
	if (s) return s;
    return [NSString stringWithFormat:@"%@.tiff",
             [self projectName]];
}


-(void)installResources;
{
	NSMutableDictionary *theDict = [NSMutableDictionary dictionary];
	NSString *filePath = [[self resourcePath] stringByAppendingPathComponent:@"Info-gnustep.plist"];
	[super installResources];
	[theDict setObject:@"Project built with nfmake()" forKey:@"Note"];
	[theDict setObject:[self projectName] forKey:@"NSExecutable"];
	[theDict setObject:[self mainNibFile] forKey:@"NSMainNibFile"];
	[theDict setObject:[self appIcon] forKey:@"NSIcon"];
	[theDict setObject:[self applicationClass] forKey:@"NSPrincipalClass"];
	[theDict writeToFile:filePath atomically:YES];
}

- (void)makeTarget:(NSString *)targetName;
{
  if ([targetName isEqualToString:@"default"]) {
    [self buildSubprojects:targetName];
    [self buildClasses];
    [self installResources];
    [self linkFinalProduct];
  } else {
    [super makeTarget:targetName];
  }
}


@end
