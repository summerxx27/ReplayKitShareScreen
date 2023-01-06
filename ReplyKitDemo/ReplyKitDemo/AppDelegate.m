//
//  AppDelegate.m
//  ReplyKitDemo
//
//  Created by summerxx on 2022/12/29.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [[NSURLSession.sharedSession dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com"]]] resume];
    return YES;
}

@end
