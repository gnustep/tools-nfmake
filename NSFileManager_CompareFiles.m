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

#import "NSFileManager_CompareFiles.h"



@implementation NSFileManager(compareFiles)


-(int)compareFile:(NSString *)sourceFile andFile:(NSString *)destFile;
{
  id srcDict=[self fileAttributesAtPath:sourceFile traverseLink:NO];
  id dstDict=[self fileAttributesAtPath:destFile traverseLink:NO];
  NSDate *srcDate;
  NSDate *dstDate;
  NSComparisonResult dateCompare;
  BOOL srcIsDir=NO;
  BOOL dstIsDir=NO;
  
  if (!srcDict) return FC_NO_SRC;
  if (!dstDict) return FC_NO_DEST;

  if ([[srcDict objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) srcIsDir=YES;
  if ([[dstDict objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) dstIsDir=YES;

  if (srcIsDir != dstIsDir) {
    return FC_SRC_NEWER;
  }

  if (srcIsDir) {
    NSArray *srcList = [self directoryContentsAtPath:sourceFile];
    NSArray *dstList = [self directoryContentsAtPath:destFile];
    int x = [srcList count];
    if ([srcList count] != [dstList count]) return FC_SRC_NEWER;
    while (x--) {
      id fileName = [srcList objectAtIndex:x];
      id fullSrcPath = [sourceFile stringByAppendingPathComponent:fileName];
      id fullDstPath = [destFile stringByAppendingPathComponent:fileName];
      int result = [self compareFile:fullSrcPath andFile:fullDstPath];
      if (result!=FC_IDENTICAL) return FC_SRC_NEWER;
    }
  }
  srcDate = [srcDict objectForKey:NSFileModificationDate];
  dstDate = [dstDict objectForKey:NSFileModificationDate];
  dateCompare=[srcDate compare:dstDate];
  if (dateCompare == NSOrderedDescending) return FC_SRC_NEWER;
  if (dateCompare == NSOrderedAscending) return FC_DST_NEWER;
  return FC_IDENTICAL;
}


-(void) makeRecursiveDirectory:(NSString *)thePath attributes:(NSDictionary *)aDict;
{
  BOOL isDir;
  
  if (!thePath) return;
  if ([thePath isEqualToString:@"/"]) return;
  if ([thePath isEqualToString:@"."]) return;
  if ([thePath isEqualToString:@""]) return;


  if ([self fileExistsAtPath:thePath isDirectory:&isDir]) {
    if (isDir) {
      return;
    } else {
      NSLog(@"Cannot make directory %@, because %@ is a file in the way",thePath);
      return;
    }
  } else {
      [self makeRecursiveDirectory:[thePath stringByDeletingLastPathComponent] attributes:aDict];
      //NSLog(@"mkdir %@ %@",thePath,aDict);
      [self createDirectoryAtPath:thePath attributes:aDict];
  }
}
-(void) makeRecursiveDirectory:(NSString *)thePath;
{
    NSDictionary *newDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:0755],NSFilePosixPermissions,nil];
  [self  makeRecursiveDirectory:thePath attributes:newDict];
}

-(NSString *)newerFile:(NSString *)file1 :(NSString *)file2;
{
  int result=[self compareFile:file1 andFile:file2];
  switch(result) {
    case FC_IDENTICAL:
      return file2;
    case FC_DST_NEWER:
      return file2;
    default:
      return file1;
  }
}

-(BOOL)file:(NSString *)linkTarget isOlderThanFiles:(NSArray *)dependancies;
{
  id theEnum = [dependancies objectEnumerator];
  id fileName;
  while ((fileName =[theEnum nextObject])) {
    if ([self newerFile:fileName :linkTarget]==fileName) return YES;
  }
  return NO;
}

-(NSArray *)expandDirectories:(NSArray *)fileList;
{
  NSMutableArray *retArray = [fileList mutableCopy];
  int x;
  
  [retArray autorelease];
  for (x=0 ; x < [retArray count]; x++) {
     BOOL isDir;
     id afile= [retArray objectAtIndex:x];
     if ([self fileExistsAtPath:afile isDirectory:&isDir] && isDir) {
        NSEnumerator *theEnum= [self enumeratorAtPath:afile];
        id fullFilePath;
        //NSLog(@"Scanning %@",afile);
        while (fullFilePath = [theEnum nextObject]) {
          NSString *fullPath = [NSString stringWithFormat:@"%@/%@",afile,fullFilePath];
          BOOL isDir2;
          
          if ([self fileExistsAtPath:fullPath isDirectory:&isDir2] && isDir2) {
            continue;
          }
          [retArray addObject:fullPath];
        }
        [retArray replaceObjectAtIndex:x withObject:@""];
     }
  }
  x = [retArray count];
  while (x--) {
    if ([[retArray objectAtIndex:x] isEqualToString:@""]) [retArray removeObjectAtIndex:x];
  }
  return retArray;
}


-(void)updateFiles:(NSArray *)fileList toDirectory:(NSString *)theDir operationDelegate:opDelegate;
{
  id theEnum;
  id theMan=self;
  id fileName;

  fileList=[self expandDirectories:fileList];
  theEnum = [fileList objectEnumerator];
  while ((fileName = [theEnum nextObject])) {
    NSString *destPath = [theDir stringByAppendingPathComponent:fileName];
    int result=[theMan compareFile:fileName andFile:destPath];
    NSString *targetDir = [destPath stringByDeletingLastPathComponent];
    BOOL isDir;

    if ([opDelegate shouldCopyFile:fileName toDest:destPath]==NO) continue;

    if ([self fileExistsAtPath:targetDir isDirectory:&isDir]) {
      if (!isDir) NSLog(@"%@ should be a directory",targetDir);
    } else {
      [self makeRecursiveDirectory:targetDir]; 
    }

    if (result==FC_IDENTICAL || result==FC_DST_NEWER) {
      //fprintf(stdout," up to date %s\n",[fileName cString]);
      continue;
    }

    if (result==FC_SRC_NEWER) {
      [theMan removeFileAtPath:destPath handler:nil];
      fprintf(stdout,"===Updating   %s\n",[fileName cString]);
    } else {
       fprintf(stdout,"===Copying    %s\n",[fileName cString]);
    }

    if ([theMan copyPath:fileName toPath:destPath handler:nil]==NO) {
      fprintf(stderr," ERROR: could not copy %s to %s (%d)\n",[fileName cString],[destPath cString], result);
    } else {
      [opDelegate copiedFile:fileName toDest:destPath];
      //fprintf(stdout," copied %s\n",[fileName cString]);
    }
  }
}

- (void)updateFiles:(NSArray *)fileList toDirectory:(NSString *)theDir;
{
 [self updateFiles:fileList toDirectory:theDir operationDelegate:self];
}

- (BOOL)shouldCopyFile:(NSString *)srcFile toDest:(NSString *)destFile;
{
  // default is to copy all files
  //NSLog(@"shld :%@",srcFile);
  return YES;
}

- (void)copiedFile:(NSString *)srcFile toDest:(NSString *)destFile;
{
}

- (void)installFromPath:(NSString *)sourcePath 
                  toDir:(NSString *)destDir
      operationDelegate:opDelegate;
{
  NSString *cwd = [self currentDirectoryPath];
  NSString *sourceFileName = [sourcePath lastPathComponent];
  NSString *sourceDirName = [sourcePath stringByDeletingLastPathComponent];
  NSString *destFileName = [destDir stringByAppendingPathComponent:sourceFileName];
  
  [self makeRecursiveDirectory:destDir];
  [self removeFileAtPath:destFileName handler:nil];
  [self changeCurrentDirectoryPath:sourceDirName];
  [self updateFiles:[NSArray arrayWithObject:sourceFileName]
        toDirectory:destDir
  operationDelegate:opDelegate];
  [self changeCurrentDirectoryPath:cwd];
}

@end
