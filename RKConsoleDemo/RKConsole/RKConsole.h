//
//  RKConsole.h
//  RKConsole
//
//  Created by ch on 2018/6/21.
//  Copyright © 2018年 rinki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifndef RKShareConsole
#define RKShareConsole [RKConsole shareInstance]
#endif

#if DEBUG
// DEBUG
#define WQColor(r,g,b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]

#define RKLogErr(FORMAT,...) [RKShareConsole log:WQColor(255,0,0) \
file:[[NSString stringWithUTF8String:__FILE__] lastPathComponent] \
line:__LINE__ \
thread:[NSThread currentThread] \
log:(FORMAT), ## __VA_ARGS__]

#define RKLog(FORMAT,...) [RKShareConsole log:WQColor(32,102,235) \
file:[[NSString stringWithUTF8String:__FILE__] lastPathComponent] \
line:__LINE__ \
thread:[NSThread currentThread] \
log:(FORMAT), ## __VA_ARGS__]

#else
// Release
#define RKLogErr(FORMAT,...) {}
#define RKLog(FORMAT,...) {}
#endif

@interface RKConsole : NSObject
@property (nonatomic, strong) UIColor *consoleColor;
@property (assign,nonatomic) BOOL showCrashLog;//是否只展示崩溃日志,默认不展示崩溃日志
+ (instancetype)shareInstance;
- (void)openViewLog;
- (void)startExceptionHandler;//开启崩溃记录,把最后一次崩溃信息报错到 NSUserDefault

/**
 内部日志获取函数，不用理会
 */
- (void)log:(UIColor *)color
       file:(NSString *)file
       line:(int)line
     thread:(NSThread *)thread
        log:(NSString *)log,...;
@end
