/* 
   Copyright (C) 2000 Free Software Foundation, Inc.
   
   Written by:	Karl Kraft <karl@nfox.com>
   Date: 		Apr 00
   
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

#import "NFOXComponentStyle.h"
#import <unistd.h>
#import "NSFileManager_CompareFiles.h"

@implementation NFOXComponentStyle
+(BOOL)buildsType:(NSString *)aType;
{
  if ([aType isEqualToString:@"NFOXComponent"]) {
    return YES;
  }
  return NO;
}

- (NSString *)componentName;
{
  NSString *extension = [self buildExtension];
  if (extension) {
    return [NSString stringWithFormat:@"%@.%@",
             [self projectName],extension];
  } else {
    return [NSString stringWithFormat:@"%@.build",
	   [self projectName]];
  }
}
-(NSString *)componentPath;   // where the component is assembled
{
return [[self buildComponentDirectory] stringByAppendingPathComponent:[self componentName]];
}

-(void)linkFinalProduct;
{
  NSTask *aTask = [[[NSTask alloc] init] autorelease];
  NSMutableArray *arguments= [NSMutableArray array];
  NSString *infoPath;

  if ([[NSFileManager defaultManager] file:[self executablePath] isOlderThanFiles:[self linkables]]==NO) {

//    fprintf(stdout,"up to date\n");
    return;
  }

  fprintf(stdout,"Linking %s\n",[[self executablePath] cString]); fflush(stdout);

  //[arguments addObject:@"-v"];
  [arguments addObjectsFromArray:[self cFlagArray]];
  [arguments addObject:@"-shared"];
  [arguments addObject:@"-o"];
  [arguments addObject:[self executablePath]];
  [arguments addObjectsFromArray:[self linkables]];
  [arguments addObjectsFromArray:[self libraryDirectoryFlags]];

//  [arguments addObjectsFromArray:[self frameworkLinkFlags]];
  

  [aTask setLaunchPath:@"gcc"];
  [aTask setArguments:arguments];
//NSLog(@"%@",arguments);
  [aTask launch];
  sleep(30);
  [aTask waitUntilExit];
  if ([aTask terminationStatus]!=0) {
    fprintf(stderr,"Abort\n");
    exit([aTask terminationStatus]);
  } else {
  }
  infoPath = [[self componentPath] stringByAppendingPathComponent:@"Info.plist"];
  {
   NSMutableDictionary *theDict=[NSMutableDictionary dictionary];
   [theDict setObject:[self projectName] forKey:@"NSExecutable"];
   [theDict writeToFile:infoPath atomically:YES];
  }

}

-(void)installBundle;
{
  NSFileManager *theMan=[NSFileManager defaultManager];
  NSString *installDirectory=[self installDirectory];
  NSString *destRoot;

  if (!installDirectory) {
    //NSLog(@"no INSTALLDIR set using /usr/GNUstep/Local/Components");
    installDirectory = @"/usr/GNUstep/Local/Components";
  }

  [theMan makeRecursiveDirectory:installDirectory];
  destRoot = [installDirectory stringByAppendingPathComponent:[self componentName]];
  [theMan removeFileAtPath:destRoot handler:nil];
  if ([theMan copyPath:[self componentPath] toPath:destRoot handler:nil]==NO) {
    fprintf(stderr," ERROR: could not install %s\n",[destRoot cString]);
    exit(-1);
  } else {
    fprintf(stdout," installed %s\n",[destRoot cString]);
  }

}


-(void)makeTarget:(NSString *)targetName;
{
  if ([targetName isEqualToString:@"default"]) {
    [self buildSubprojects:targetName];
    [self buildClasses];
    [self installHeaders];
    [self installResources];
    [self linkFinalProduct];
  } else  if ([targetName isEqualToString:@"install"]) {
    [self makeTarget:@"default"];
    [self installBundle];
  } else {
    [super makeTarget:targetName];
  }
}



@end
