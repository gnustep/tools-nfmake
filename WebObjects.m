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

#import "WebObjects.h"
#import <unistd.h>
#import "NSFileManager_CompareFiles.h"


@implementation WebObjects

- (NSString *)componentName;
{
  NSString *extension = [self buildExtension];
  if (extension) {
    return [NSString stringWithFormat:@"%@.%@",
             [self projectName],extension];
  } else {
    return [NSString stringWithFormat:@"%@.gswa",
	   [self projectName]];
  }
}
-(NSString *)componentPath;   // where the component is assembled
{
return [[self buildWebObjectsDirectory] stringByAppendingPathComponent:[self componentName]];
}

+(BOOL)buildsType:(NSString *)aType;
{
  if ([aType isEqualToString:@"WebObjectsApplication"]) {
    return YES;
  }
  return NO;
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

-(NSString *)serverResourcePath;
{
  return [[self componentPath] stringByAppendingPathComponent:@"ServerResources"];
}

// The only reason for subbing this out to a new task is that prepping a file for 
// GNUstep based WebObjects is very much a personal thing, (site dependant), and
// our own implementation uses many frameworks which aren't available when bootstrapping nfmake
- (void)cleanHTMLFile:(NSString *)theFile;
{
  NSTask *aTask = [[[NSTask alloc] init] autorelease];
  NSMutableArray *arguments= [NSMutableArray array];


  [arguments addObject:theFile];
  [aTask setLaunchPath:@"prep_gswc"];
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



// installs anything defined by WEBSERVER_RESOURCES in the root PB.project
// but does it for a specific component.
// This allows you to have Main.gswc/images/foo.gif be rewritten as
// Foo.gswa/ServerResuorces/images/Main/foo.gif
// and then copy ServerResources to the web server (thus saving the round trip to the app server)

- (void)installWebServerResources:(NSArray *)webServerResources forComponent:(NSString *)fileName;
{
  int x;
  id theMan = [NSFileManager defaultManager];
  for (x=0 ; x< [webServerResources count]; x++) {
    NSString *webServerItem= [webServerResources objectAtIndex:x];
    NSString *spreadDir=[NSString stringWithFormat:@"%@/%@",fileName,webServerItem];
    NSString *targetDir;
    if ([theMan fileExistsAtPath:spreadDir ]) {
      id parentDirectory = [theMan currentDirectoryPath];
      NSArray *subItems = [theMan directoryContentsAtPath:spreadDir];

      targetDir = [[self serverResourcePath] stringByAppendingPathComponent:webServerItem];
      targetDir = [targetDir stringByAppendingPathComponent:fileName];
      targetDir = [targetDir stringByDeletingPathExtension];

      [theMan changeCurrentDirectoryPath:spreadDir];
	    [theMan updateFiles:subItems
	            toDirectory:targetDir 
	      operationDelegate:self];
      [theMan changeCurrentDirectoryPath:parentDirectory];

    }
  }
}

- (NSArray *)componentSpreadResources;
{
  return   [[self filesTable] objectForKey:@"WEBSERVER_RESOURCES"];
}


// This installs things like Main.gswc into Resources to be used by the AppServer
 // rewrites any .html files
- (void)installWoComponents;
{
  NSArray *theArray;
  id theMan = [NSFileManager defaultManager];
  int x;
  theArray = [[self filesTable] objectForKey:@"WO_COMPONENTS"];
  for (x=0 ; x< [theArray count]; x++) {
    id theComponent = [theArray objectAtIndex:x];
    [theMan updateFiles:[NSArray arrayWithObject:theComponent]
            toDirectory:[self resourcePath] 
      operationDelegate:self];
    [self installWebServerResources:[self componentSpreadResources] forComponent:theComponent];
  }

}

- (BOOL)shouldCopyFile:(NSString *)srcFile toDest:(NSString *)destFile;
{
  return YES;
}

- (void)copiedFile:(NSString *)srcFile toDest:(NSString *)destFile;
{
  if ([[destFile pathExtension] isEqualToString:@"html"]) {
    //NSLog(@"Cleaning %@",srcFile);
    [self cleanHTMLFile:destFile];
  }
}

- (void)installResources;
{
  NSArray *theArray;
  id theMan = [NSFileManager defaultManager];

  [super installResources];
  [theMan makeRecursiveDirectory:[self resourcePath]];
  [theMan makeRecursiveDirectory:[self serverResourcePath]];

  theArray = [[self filesTable] objectForKey:@"WEBSERVER_RESOURCES"];
  if (theArray && [theArray count]) {
    [theMan updateFiles:theArray toDirectory:[self serverResourcePath]];
  }

  theArray = [[self filesTable] objectForKey:@"WOAPP_RESOURCES"];
  if (theArray && [theArray count]) {
    [theMan updateFiles:theArray toDirectory:[self resourcePath]];
  }
  [self installWoComponents];
}

- (void)install;
{
  NSFileManager *theMan=[NSFileManager defaultManager];
  NSString *installDirectory=[self installDirectory];

  if (!installDirectory) {
    //NSLog(@"no INSTALLDIR set using /usr/GNUstep/Local/Components");
    installDirectory = @"/usr/GNUstep/Local/WOApps";
  }

  fprintf(stdout,"Installing to %s\n",[installDirectory cString]);
  [theMan installFromPath:[self componentPath] 
                    toDir:installDirectory 
        operationDelegate:[self copyDelegate]];

}

-(void)makeTarget:(NSString *)targetName;
{
  if ([targetName isEqualToString:@"default"]) {
    [self installResources];
    [self buildSubprojects:targetName];
    [self buildClasses];
    [self linkFinalProduct];
  } else if ([targetName isEqualToString:@"install"]) {
    [self makeTarget:@"default"];
    [self install];
  } else {
    [super makeTarget:targetName];
  }
}



@end
