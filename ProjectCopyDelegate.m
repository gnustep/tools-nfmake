#import "ProjectCopyDelegate.h"

@implementation  ProjectCopyDelegate


- (BOOL)shouldCopyFile:(NSString *)srcPath toDest:(NSString *)destFile;
{
  NSRange r;
  NSString *srcFile = [srcPath lastPathComponent];
  // CVS Folders
  r=[srcPath rangeOfString:@"/CVS/"];
  if (r.length) return NO;
  // backup bundles/wrappers
  r=[srcPath rangeOfString:@"~/"];
  if (r.length) return NO;
  // backup bundles/wrappers
  if ([srcFile hasSuffix:@"~"]) return NO;
  // In Progress - jcc
  if ([srcFile hasSuffix:@"#"] && [srcFile hasSuffix:@"#"]) return NO;
 return YES;
}

- (void)copiedFile:(NSString *)srcFile toDest:(NSString *)destFile;
{
  NSFileManager *theMan = [NSFileManager defaultManager];
  NSDictionary *oldDict = [theMan fileAttributesAtPath:destFile
			  traverseLink:NO];
  unsigned long theValue = [[oldDict objectForKey:NSFilePosixPermissions] longValue];
  unsigned long newValue = theValue;
  // readable by me, readable by all
  if ( theValue & 0400) {
    newValue = newValue | 0444;
  }
  // executable by me, executable by all
  if ( theValue & 0100) {
    newValue = newValue | 0111;
  }
  if (theValue != newValue) {
    NSDictionary *newDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:newValue],NSFilePosixPermissions,nil];
    [theMan changeFileAttributes:newDict atPath:destFile];
  }
  //NSLog(@"perm:%@",destFile);
}

@end