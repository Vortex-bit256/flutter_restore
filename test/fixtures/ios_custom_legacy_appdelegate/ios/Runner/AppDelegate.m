@import Flutter;
#import "GeneratedPluginRegistrant.h"

@interface AppDelegate : FlutterAppDelegate <FlutterImplicitEngineDelegate>
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  FlutterEngine *engine = [[FlutterEngine alloc] initWithName:@"legacy"];
  [GeneratedPluginRegistrant registerWithRegistry:self];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}
- (void)didInitializeImplicitFlutterEngine:(FlutterEngine*)engine {}
@end
