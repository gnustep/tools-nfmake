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

#import "PBProject.h"
#import "NSObject.h"
#import "NSFileManager_CompareFiles.h"

@implementation PBProject

- (BOOL)buildsType:(NSString *)aType;
{
	return NO;
}

+(PBProject *)builderForProject:(PBProject *)aProject;
{
  id theEnum = [[self loadedSubclassArray] objectEnumerator];
  id theClass;
  while ((theClass = [theEnum nextObject])) {
    if ([theClass buildsType:[aProject projectType]]) {
      id builder = [[[theClass alloc] init] autorelease];
      return builder;
    }
  }
  NSLog(@"type %@ is not implemented",[aProject projectType]);
  {
    id builder = [[[self alloc] init] autorelease];
    return builder;
  }
}


// childList is a list of subprojects
-(NSMutableArray *)childList;
{
  if (!childList) {
    childList = [[NSMutableArray alloc] init];
  }
  return childList;
}

- (void)addChild:(PBProject *)aProject;
{
  [[self childList] addObject:aProject];
}

// called if we are a subproject
- (void)setParentProject:aProject;
{
  parentProject = [aProject retain];
  [parentProject addChild:self];
}
- (PBProject *)parentProject;
{
  return parentProject;
}

- (PBProject *)baseProject;
{
  PBProject *baseProject = self;
  while ([baseProject parentProject]) {
    baseProject = [baseProject parentProject];
  }
  return baseProject;
}

// aDict is the actual contents of PB.project
-(void)setDictionary:(NSDictionary *)aDict;
{
  if (initialDictionary) {
    [initialDictionary release];
    initialDictionary=nil;
  }
  initialDictionary= [aDict copy];
}

-(void)setBaseDirectoryPath:(NSString *)aString;
{
  baseDirectoryPath = [aString copy];
}

-(NSString *)baseDirectoryPath;
{
  return baseDirectoryPath;
}

// give the path to a PB.project, finds a suitable subclass to build the project
// and sets it up for building
+(PBProject *)parse:(NSString *)aPath;
{
  id aDict = [NSDictionary dictionaryWithContentsOfFile:aPath];
  id newProject;
  if (!aDict) return nil;
  newProject = [[[self alloc] init] autorelease];
  [newProject setDictionary:aDict];
  [newProject setBaseDirectoryPath:[[NSFileManager defaultManager] currentDirectoryPath]];
  newProject = [self builderForProject:newProject];
  [newProject setDictionary:aDict];
  [newProject setBaseDirectoryPath:[[NSFileManager defaultManager] currentDirectoryPath]];
  return newProject;
}


/*
 *  Items returns from the PB.project file
*/


// A dictionary of files (keyed by type) needed to build the project
-(NSDictionary *)filesTable;
{
  return [initialDictionary objectForKey:@"FILESTABLE"];
}

// A list of classes and pseudo class files to compile (typically .c and .m files
-(NSArray *)classes;
{
  NSArray *baseArray=[NSArray array];
  baseArray= [baseArray arrayByAddingObjectsFromArray:[[self filesTable] objectForKey:@"CLASSES"]];
  baseArray= [baseArray arrayByAddingObjectsFromArray:[[self filesTable] objectForKey:@"OTHER_LINKED"]];
  return baseArray;
  
}

// A list of strings, each being the name of a directory that contains a subproject
-(NSArray *)subProjectNames;
{  
  return [[self filesTable] objectForKey:@"SUBPROJECTS"];
}

- (NSString *)projectType;
{
  return [initialDictionary objectForKey:@"PROJECTTYPE"];
}

// per project values
-(NSString *)projectName;
{
  return [initialDictionary objectForKey:@"PROJECTNAME"];
}

- (NSString *)installDirectory;
{
  NSString *installDir=[initialDictionary objectForKey:@"INSTALLDIR"];
  if (installDir) {
    // TODO - expand out ~ and perhaps $(HOME)
    return installDir;
  }
  return nil;
}

- (NSString *)buildExtension;
{
  return [initialDictionary objectForKey:@"BUNDLE_EXTENSION"];
}

- (NSString *)installRoot; /// the root of where to install finished products
{
	id baseDict = [[NSProcessInfo processInfo] environment];
	id userSpecifiedPath = [baseDict objectForKey:@"GNUSTEP_BUILD_ROOT"];
	if (userSpecifiedPath) {
    return userSpecifiedPath;
	} else {
	  return [NSHomeDirectory() stringByAppendingPathComponent:@"spool"];
  }
}

/*
 *  Things created based on the contents of PB.project
 */
// returns all the subproject creating them if needed
-(NSArray *)subProjects;
{
  if (!childList) {

    id subProjectList=[self subProjectNames];
    if (subProjectList && [subProjectList count]) {
      id theEnum = [subProjectList objectEnumerator];
      id directoryName;
      id theMan = [NSFileManager defaultManager];
      id parentDirectory = [theMan currentDirectoryPath];


      while ((directoryName= [theEnum nextObject])) {
        PBProject *subProject;
        if ([theMan changeCurrentDirectoryPath:directoryName]) {
	        subProject=[PBProject parse:@"PB.project"];
	        [subProject setParentProject:self];
	      } else {
	        NSLog(@"Can't build subproject %@, directory missing",directoryName);
	      }
        [theMan changeCurrentDirectoryPath:parentDirectory];
      }

    }
  }
  return [self childList];
}

/*
 *  Things determined for a specific file
 */
// given a source file, provides a path for a .o file
-(NSString *)compileTargetForSource:(NSString *)classFile;
{
  NSString *outputFile;
  outputFile = [NSString stringWithFormat:@"%@/%@.o",[self outputDirectory], [classFile stringByDeletingPathExtension]];
  return outputFile;
}

// provides a list of all .o files, even those used by subprojects that should be linked into the final product
-(NSArray *)linkables;
{
  NSArray *sourceFiles = [self classes];
  NSMutableArray *outputArray = [NSMutableArray array];
  id theEnum = [sourceFiles objectEnumerator];
  id theClass;
  id subProjectList=[self subProjects];

  while ((theClass=[theEnum nextObject])) {
    [outputArray addObject:[self compileTargetForSource:theClass]];

  }

  if (subProjectList && [subProjectList count]) {
    id theSubProject;
    theEnum = [subProjectList objectEnumerator];
    while (theSubProject=[theEnum nextObject]) {
      [outputArray addObjectsFromArray:[theSubProject linkables]];
    }
  }

  return outputArray;
}


- (NSString *)buildComponentDirectory; // where resuable components go when installed
{
  static BOOL dirExists=NO;
  NSString *theDir = [[self installRoot] stringByAppendingPathComponent:@"Components"];
  if (!dirExists) {
    [[NSFileManager defaultManager] makeRecursiveDirectory:theDir];
  } 
  return theDir;
}

- (NSString *)buildWebObjectsDirectory; // where WebObjects Applications go when built
{
  static BOOL dirExists=NO;
  NSString *theDir = [[self installRoot] stringByAppendingPathComponent:@"WOApps"];
  if (!dirExists) {
    [[NSFileManager defaultManager] makeRecursiveDirectory:theDir];
  } 
  return theDir;
}

- (NSString *)buildFrameworkDirectory; // where resuable components go when installed
{
  static BOOL dirExists=NO;
  NSString *theDir = [[self installRoot] stringByAppendingPathComponent:@"Frameworks"];
  if (!dirExists) {
    [[NSFileManager defaultManager] makeRecursiveDirectory:theDir];
  } 
  return theDir;
}

- (NSString *)buildHeaderDirectory; // where framework headers go on install
{
  static BOOL dirExists=NO;
  NSString *theDir = [[self installRoot] stringByAppendingPathComponent:@"Headers"];
  if (!dirExists) {
    [[NSFileManager defaultManager] makeRecursiveDirectory:theDir];
  } 
  return theDir;
}

- (NSString *)buildLibraryDirectory; // where framework headers go on install
{
  static BOOL dirExists=NO;
  NSString *theDir = [[self installRoot] stringByAppendingPathComponent:@"lib"];
  if (!dirExists) {
    [[NSFileManager defaultManager] makeRecursiveDirectory:theDir];
  } 
  return theDir;
}


-(NSString *)rootBuildDirectory;  // a temp place to use for builds
{
  if (parentProject) {
    return [parentProject outputDirectory];
  } else {
    return [[self installRoot] stringByAppendingPathComponent:@"build"];
  }
}

-(NSString *)cFlags;  // flags to pass to the compiler
{
  return [[self installRoot] stringByAppendingPathComponent:@""];
}



-(NSString *)outputDirectory;  // root of build output for this project
{
  return [[self rootBuildDirectory] stringByAppendingPathComponent:[self projectName]];
}



-(NSString *)componentPath;   // where the component is assembled
{
  NSString *extension = [self buildExtension];
  if (extension) {
    return [NSString stringWithFormat:@"%@/%@.%@",
             [self outputDirectory],
             [self projectName],extension];
  } else {
    return [NSString stringWithFormat:@"%@/%@.build",
           [self outputDirectory],
	   [self projectName]];
  }
}

-(NSString *)executablePath;  // where the executable code is placed
{
  return [[self componentPath] stringByAppendingPathComponent:[self projectName]];
}

-(NSString *)publicHeaderPath;
{
  if (parentProject) return [parentProject publicHeaderPath];
  return [[self componentPath] stringByAppendingPathComponent:@"Headers"];
}

-(NSString *)projectHeaderPath;
{
  if (parentProject) return [parentProject projectHeaderPath];
  return [[self componentPath] stringByAppendingPathComponent:@"PrivateHeaders"];
}

-(NSString *)resourcePath;
{
  return [[self componentPath] stringByAppendingPathComponent:@"Resources"];
}

- (NSDictionary *)userSettings;
{
	id baseDict = [[NSProcessInfo processInfo] environment];
	id userSpecifiedPath = [baseDict objectForKey:@"NFMAKE_SETTINGS_FILE"];
	if (userSpecifiedPath) {
	  userSettings = [NSDictionary dictionaryWithContentsOfFile:userSpecifiedPath];
	  [userSettings retain];
	} else {
	  userSettings = [[NSDictionary dictionary] retain];
	}
	
	return userSettings;
}

- (NSArray *)systemCFlagArray;
{
	id theArray = [[self userSettings] objectForKey:@"CFLAGS"];
	if (theArray) {
	  return theArray;
	} else {
		return [NSArray array];
	}
}

- (NSArray *)cFlagArray;
{
  id parentArray = nil;
  id myString;
  if (parentProject) {
    parentArray = [parentProject cFlagArray];
  }
  if (!parentArray) parentArray = [NSMutableArray array];

  [parentArray addObjectsFromArray:[self systemCFlagArray]];
  myString =[initialDictionary objectForKey:@"GNUSTEP_COMPILEROPTIONS"];
  [parentArray addObjectsFromArray:[myString componentsSeparatedByString:@" "]];
  return parentArray;
}

- (NSArray *)frameworkShortNames;
{
  NSMutableArray *retArray=[NSMutableArray array];
  NSArray *baseArray= [[self filesTable] objectForKey:@"FRAMEWORKS"];
  int x = [baseArray count];
  while (x--) {
    id frameworkName = [[baseArray objectAtIndex:x] stringByDeletingPathExtension]; 
    [retArray addObject:frameworkName];
  }
  return retArray;
}


- (NSArray *)frameworkLinkFlags;
{

  NSMutableArray *retArray=[NSMutableArray array];
  NSArray *baseArray= [[self filesTable] objectForKey:@"FRAMEWORKS"];
  int x = [baseArray count];
  while (x--) {
    id frameworkName = [[baseArray objectAtIndex:x] stringByDeletingPathExtension]; 
    if ([frameworkName isEqualToString:@"Foundation"]) frameworkName = @"gnustep-base";
    if ([frameworkName isEqualToString:@"AppKit"]) frameworkName = @"gnustep-xgps";
    [retArray addObject:[NSString stringWithFormat:@"-l%@",frameworkName]];
  }
  baseArray= [[self filesTable] objectForKey:@"LIBRARIES"];
  x = [baseArray count];
  while (x--) {
    [retArray addObject:[NSString stringWithFormat:@"-l%@",[baseArray objectAtIndex:x]]];
  }
  [retArray addObject:[NSString stringWithFormat:@"-l%@",@"objc"]];
  [retArray addObject:[NSString stringWithFormat:@"-l%@",@"pthread"]];
  return retArray;
}
  
- (NSArray *)executableLinkFlags;
{
  NSMutableArray *retArray=[NSMutableArray array];
  [retArray addObjectsFromArray:[self frameworkLinkFlags]];
  [retArray addObject:[NSString stringWithFormat:@"-l%@",@"objc"]];
  [retArray addObject:[NSString stringWithFormat:@"-l%@",@"pthread"]];
  return retArray;
}

-(NSDictionary *)subTaskEnvironment;
{
	id baseDict = [[NSProcessInfo processInfo] environment];
	id theDict = [NSMutableDictionary dictionaryWithDictionary:baseDict];
	[theDict setObject:[baseDict objectForKey:@"LD_LIBRARY_PATH"] forKey:@"LD_LIBRARY_PATH"];
	return theDict;
}

-(NSArray *)libraryDirectoryFlags;
{
	id baseDict = [[NSProcessInfo processInfo] environment];
  id thePathList = [baseDict objectForKey:@"LD_LIBRARY_PATH"];
  id pathParts = [thePathList componentsSeparatedByString:@":"];
  id theMan = [NSFileManager defaultManager];
  NSMutableArray *outArray = [NSMutableArray array];
  int x;

  pathParts=[pathParts mutableCopy];
  [pathParts autorelease];
  if ([initialDictionary objectForKey:@"OTHER_LIB_DIR"]) {
	  [pathParts addObjectsFromArray:[initialDictionary objectForKey:@"OTHER_LIB_DIR"]];
  }
  x= [pathParts count];
  while (x--) {
    NSString *theDir = [pathParts objectAtIndex:x];
    BOOL isDir;
    if ([theMan fileExistsAtPath:theDir isDirectory:&isDir] && isDir) {
	    [outArray addObject:[NSString stringWithFormat:@"-L%@",theDir]];
    }
  }
  return outArray;
}

-(NSArray *)headerDirectoryFlags;
{
  id theMan = [NSFileManager defaultManager];
  NSMutableArray *outArray = [NSMutableArray array];
	id baseDict = [[NSProcessInfo processInfo] environment];
  NSMutableArray *potentialArray = [NSMutableArray array];
  int x;
  NSString *hostPath = [NSString stringWithFormat:@"Headers/%@/%@",
    [baseDict objectForKey:@"GNUSTEP_HOST_CPU"],
    [baseDict objectForKey:@"GNUSTEP_HOST_OS"]];
  [potentialArray addObject:[[baseDict objectForKey:@"GNUSTEP_SYSTEM_ROOT"] stringByAppendingPathComponent:@"Headers"]];
  [potentialArray addObject:[[baseDict objectForKey:@"GNUSTEP_SYSTEM_ROOT"] stringByAppendingPathComponent:@"Headers/gnustep"]];
  [potentialArray addObject:[[baseDict objectForKey:@"GNUSTEP_SYSTEM_ROOT"] stringByAppendingPathComponent:hostPath]];
  
  [potentialArray addObject:[[baseDict objectForKey:@"GNUSTEP_NETWORK_ROOT"] stringByAppendingPathComponent:@"Headers"]];
  [potentialArray addObject:[[baseDict objectForKey:@"GNUSTEP_NETWORK_ROOT"] stringByAppendingPathComponent:@"Headers/gnustep"]];
  [potentialArray addObject:[[baseDict objectForKey:@"GNUSTEP_NETWORK_ROOT"] stringByAppendingPathComponent:hostPath]];

  [potentialArray addObject:[[baseDict objectForKey:@"GNUSTEP_LOCAL_ROOT"] stringByAppendingPathComponent:@"Headers"]];
  [potentialArray addObject:[[baseDict objectForKey:@"GNUSTEP_LOCAL_ROOT"] stringByAppendingPathComponent:@"Headers/gnustep"]];
  [potentialArray addObject:[[baseDict objectForKey:@"GNUSTEP_LOCAL_ROOT"] stringByAppendingPathComponent:hostPath]];

  [potentialArray addObject:[[baseDict objectForKey:@"GNUSTEP_BUILD_ROOT"] stringByAppendingPathComponent:@"Headers"]];
  [potentialArray addObject:[[baseDict objectForKey:@"GNUSTEP_BUILD_ROOT"] stringByAppendingPathComponent:@"Headers/gnustep"]];
  [potentialArray addObject:[[baseDict objectForKey:@"GNUSTEP_BUILD_ROOT"] stringByAppendingPathComponent:hostPath]];

  if ([initialDictionary objectForKey:@"OTHER_HEADER_DIR"]) {
	  [potentialArray addObjectsFromArray:[initialDictionary objectForKey:@"OTHER_HEADER_DIR"]];
  }


  
  x = [potentialArray count];
  while (x--) {
    NSString *theDir = [potentialArray objectAtIndex:x];
    BOOL isDir;
    if ([theMan fileExistsAtPath:theDir isDirectory:&isDir] && isDir) {
	    [outArray addObject:[NSString stringWithFormat:@"-I%@",theDir]];
    }
  }
  return outArray;
}

- (NSString *)principalClassName;
{
  NSString *className = [initialDictionary objectForKey:@"PRINCIPALCLASS"];
  if (!className && [[self classes] count]) {
    className = [[[self classes] objectAtIndex:0] stringByDeletingPathExtension];
  }
  return className;
}
@end
