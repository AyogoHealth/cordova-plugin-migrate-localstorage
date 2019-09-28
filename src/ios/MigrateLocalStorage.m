#import "MigrateLocalStorage.h"

@implementation MigrateLocalStorage

- (BOOL) copyFrom:(NSString*)src to:(NSString*)dest
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* appLibraryFolder = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];

    // create path to dest
    if (![fileManager createDirectoryAtPath:[dest stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil]) {
        return NO;
    }

    NSArray* srcFiles = [fileManager contentsOfDirectoryAtPath:src error:nil];
    BOOL success = YES;
    for (NSString *file in srcFiles) {
        NSError *err;
        NSString* srcFile = [appLibraryFolder stringByAppendingPathComponent:@"WebKit/LocalStorage/___IndexedDB"];
        srcFile = [srcFile stringByAppendingPathComponent:file];
        NSString* destFile = [appLibraryFolder stringByAppendingPathComponent:@"WebKit/WebsiteData/IndexedDB"];
        destFile = [destFile stringByAppendingPathComponent:file];
        BOOL fileSuccess = [fileManager copyItemAtPath:srcFile toPath:destFile error:&err];
        success = success && fileSuccess;
    }
    return success;
}

- (BOOL) migrateLocalStorage
{
    // Migrate UIWebView local storage files to WKWebView. Adapted from
    // https://github.com/Telerik-Verified-Plugins/WKWebView/blob/master/src/ios/MyMainViewController.m

    NSString* appLibraryFolder = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* original;

    if ([[NSFileManager defaultManager] fileExistsAtPath:[appLibraryFolder stringByAppendingPathComponent:@"WebKit/LocalStorage/file__0.localstorage"]]) {
        original = [appLibraryFolder stringByAppendingPathComponent:@"WebKit/LocalStorage"];
    } else {
        original = [appLibraryFolder stringByAppendingPathComponent:@"Caches"];
    }

    original = [original stringByAppendingPathComponent:@"file__0.localstorage"];

    NSString* target = [[NSString alloc] initWithString: [appLibraryFolder stringByAppendingPathComponent:@"WebKit"]];

#if TARGET_IPHONE_SIMULATOR
    // the simulutor squeezes the bundle id into the path
    NSString* bundleIdentifier = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    target = [target stringByAppendingPathComponent:bundleIdentifier];
#endif

    target = [target stringByAppendingPathComponent:@"WebsiteData/LocalStorage/file__0.localstorage"];

    // Only copy data if no existing localstorage data exists yet for wkwebview
    if (![[NSFileManager defaultManager] fileExistsAtPath:target]) {
        NSLog(@"No existing localstorage data found for WKWebView. Migrating data from UIWebView");
        BOOL success1 = [self copyFrom:original to:target];
        BOOL success2 = [self copyFrom:[original stringByAppendingString:@"-shm"] to:[target stringByAppendingString:@"-shm"]];
        BOOL success3 = [self copyFrom:[original stringByAppendingString:@"-wal"] to:[target stringByAppendingString:@"-wal"]];
        return success1 && success2 && success3;
    }
    else {
        return NO;
    }
}

// FIXME clean this mess up
- (BOOL) migrateIndexedDB
{
  NSString* webViewEngineClass = [ self.commandDelegate.settings objectForKey:[@"CordovaWebViewEngine" lowercaseString]];
    if ([webViewEngineClass isEqualToString:@"CDVUIWebViewEngine"]) {
        return NO;
    } else {
        NSString* appLibraryFolder = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];

        NSFileManager* fileManager = [NSFileManager defaultManager];

        NSString* original = [appLibraryFolder stringByAppendingPathComponent:@"WebKit/LocalStorage/___IndexedDB"];

        NSString* target = [[NSString alloc] initWithString: [appLibraryFolder stringByAppendingPathComponent:@"WebKit/WebsiteData/IndexedDB"]];

        if ([[NSFileManager defaultManager] fileExistsAtPath:original]) {
            NSLog(@"No existing indexed db data found for WKWebView. Migrating data from UIWebView");
            BOOL copySuccessful = [self copyFrom:original to:target];
            if (copySuccessful) {
                NSLog(@"IndexedDB migration copy successful");
                NSArray* srcFiles = [fileManager contentsOfDirectoryAtPath:original error:nil];
                BOOL deleted = YES;
                for (NSString *file in srcFiles) {
                    NSError *err;
                    NSString* srcFile = [appLibraryFolder stringByAppendingPathComponent:@"WebKit/LocalStorage/___IndexedDB"];
                    srcFile = [srcFile stringByAppendingPathComponent:file];
                    BOOL deleteSuccessful = [[NSFileManager defaultManager] removeItemAtPath:original error:&err];
                    deleted = deleted && deleteSuccessful;
                }
                if (deleted) {
                    NSLog(@"IndexedDB migration deletion successful");
                } else {
                    NSLog(@"IndexedDB migration deletion failed");
                }
                return deleted;
            } else {
                NSLog(@"IndexedDB migration copy failed");
                return NO;
            }
        } else {
            NSLog(@"No existing indexed db data found for UIWebview");
            return NO;
        }
    }
    return NO;
}

- (void) pluginInitialize
{
    BOOL idbResult = [self migrateIndexedDB];
    if (idbResult) {
        NSLog(@"Successfully migrated indexed db");
    }
}

@end
