#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import "Wilddog.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  WDGOptions *option = [[WDGOptions alloc] initWithSyncURL:@"https://wd7039035262bkoubk.wilddogio.com/"];
  [WDGApp configureWithOptions:option];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
