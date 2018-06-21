//
//  RKConsole.m
//  RKConsole
//
//  Created by ch on 2018/6/21.
//  Copyright © 2018年 rinki. All rights reserved.
//

#import "RKConsole.h"
#import "WQLogView.h"

#ifndef WQMainWidth
#define WQMainWidth CGRectGetWidth([[UIScreen mainScreen] bounds])
#endif
#ifndef WQMainHeight
#define WQMainHeight CGRectGetHeight([[UIScreen mainScreen] bounds])
#endif
#ifndef WQOrignSize
#define WQOrignSize 50
#endif
#ifndef WQShowHeight
#define WQShowHeight WQMainHeight/3
#endif

NSString * const RKCrashLogKeyForNSUserDefault = @"RKCrashLogKeyForNSUserDefault";

@interface RKConsole ()
<
WQLogViewDelegate
>
@property (nonatomic, copy) NSMutableAttributedString *logStr;
@property (nonatomic, weak) WQLogView *logView;
@property (nonatomic, weak) UIButton *logBtn;
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIPanGestureRecognizer *gesture;
@property (nonatomic, assign) BOOL isShowLog;
@property (nonatomic, assign) BOOL isPauseLog;

@end

@implementation RKConsole

static RKConsole *_instance = nil;

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[RKConsole alloc] init];
    });
    return _instance;
}

- (void)openViewLog {
    UIWindow *window;
    if (!_window) {
        window = [UIWindow new];
    }
    _window = window;
    [_window makeKeyAndVisible];
    _window.frame = CGRectMake(WQMainWidth - WQOrignSize,
                               WQMainHeight/2.0 - WQOrignSize/2.0,
                               WQOrignSize,
                               WQOrignSize);
    _window.windowLevel = UIWindowLevelStatusBar + 1;
    _window.backgroundColor = [UIColor grayColor];
    _window.layer.cornerRadius = WQOrignSize/2.0;
    _window.layer.masksToBounds = YES;
    
    // view layout
    UIButton *logBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    logBtn.frame = _window.bounds;
    logBtn.layer.cornerRadius = _window.layer.cornerRadius;
    [logBtn setTitle:@"日志"
            forState:UIControlStateNormal];
    [logBtn setTitleColor:[UIColor whiteColor]
                 forState:UIControlStateNormal];
    [logBtn addTarget:self
               action:@selector(logControl:)
     forControlEvents:UIControlEventTouchUpInside];
    [_window addSubview:logBtn];
    _logBtn = logBtn;
    
    WQLogView *logView = [[WQLogView alloc] initWithFrame:CGRectMake(0, 0, WQMainWidth, WQShowHeight)];
    logView.hidden = YES;
    logView.consoleColor = _consoleColor;
    logView.delegate = self;
    [_window addSubview:logView];
    _logView = logView;
    
    // add gesture
    UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(panGesture:)];
    [_window addGestureRecognizer:gesture];
    _gesture = gesture;
}

- (void)log:(UIColor *)color
       file:(NSString *)file
       line:(int)line
     thread:(NSThread *)thread
        log:(NSString *)log,... {
    @autoreleasepool {
        if (log) {
            NSDateFormatter *formater = [[NSDateFormatter alloc] init];
            formater.dateFormat = @"yyy-MM-dd HH:mm:ss.SSS";
            NSString *date = [formater stringFromDate:[NSDate date]];
            NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
            NSString *appName = ((NSString *)[infoDictionary objectForKey:@"CFBundleDisplayName"]).length != 0 ? [infoDictionary objectForKey:@"CFBundleDisplayName"] : [infoDictionary objectForKey:@"CFBundleName"];
            va_list list;
            NSString *threadName = [[NSThread currentThread] isMainThread] ? @"Main" : ([[NSThread currentThread].name  isEqual: @""] ? @"Child" : [NSThread currentThread].name);
            va_start(list, log);
            NSString *msg = [[NSString alloc] initWithFormat:log
                                                   arguments:list];
            NSLog(@"%@",msg);
            va_end(list);
            NSString *logStr = [NSString stringWithFormat:@"%@ %@ >> >> >> 文件: %@ -- 行号: %d -- 线程: %@ -- 日志: %@ << << <<\n",
                                date,
                                appName,
                                file,
                                line,
                                threadName,
                                msg];
            NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:logStr];
            if (color) {
                [attrStr addAttribute:NSForegroundColorAttributeName
                                value:color
                                range:NSMakeRange(0, logStr.length)];
            }
            @synchronized (_logStr) {
                if (!_logStr) {
                    _logStr = [[NSMutableAttributedString alloc] init];
                }
                [_logStr appendAttributedString:attrStr];
                if (_isShowLog && !_isPauseLog && !_showCrashLog) {
                    [_logView showLog:_logStr];
                }
            }
        }
    }
}

#pragma mark -- WQLogViewDelegate
- (void)hideLogClick {
    // 隐藏日志输出页面
    _isShowLog = NO;
    __weak typeof(self)weakself = self;
    [UIView animateWithDuration:0.5
                     animations:^{
                         weakself.window.frame = CGRectMake(WQMainWidth - WQOrignSize,
                                                    WQMainHeight/2.0 - WQOrignSize/2.0,
                                                    WQOrignSize,
                                                    WQOrignSize);
                         weakself.window.backgroundColor = [UIColor grayColor];
                         weakself.window.layer.cornerRadius = WQOrignSize/2.0;
                         weakself.logView.hidden = YES;
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             weakself.logBtn.hidden = NO;
                         }
                     }];
}

- (void)startExceptionHandler
{
    NSSetUncaughtExceptionHandler (&UncaughtExceptionHandler);
}
void UncaughtExceptionHandler(NSException *exception) {
    
    NSArray *arr = [exception callStackSymbols];//得到当前调用栈信息
    NSString *reason = [exception reason];//非常重要，就是崩溃的原因
    NSString *name = [exception name];//异常类型
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    formater.dateFormat = @"yyy-MM-dd HH:mm:ss.SSS";
    NSString *date = [formater stringFromDate:[NSDate date]];

    NSString *crashLogInfo = [NSString stringWithFormat:@"date: %@ \n exception type : %@ \n crash reason : %@ \n call stack info : %@",date, name, reason, arr];
//    NSLog(@"exception type : %@ \n crash reason : %@ \n call stack info : %@", name, reason, arr);
    [[NSUserDefaults standardUserDefaults] setObject:crashLogInfo forKey:RKCrashLogKeyForNSUserDefault];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setShowCrashLog:(BOOL)showCrashLog
{
    _showCrashLog = showCrashLog;
    if (showCrashLog) {
        NSString * crashLogInfo = [[NSUserDefaults standardUserDefaults] stringForKey:RKCrashLogKeyForNSUserDefault];
        if (crashLogInfo == nil) {
            crashLogInfo = @"";
        }
        NSMutableAttributedString * crashLogStr = [[NSMutableAttributedString alloc]initWithString:crashLogInfo];
        [_logView showLog:crashLogStr];
    }else{
        if (_isShowLog && !_isPauseLog) {
            [_logView showLog:_logStr];
        }
    }
}

- (void)recordClick {
    // 记录到文件
    @synchronized (_logStr) {
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask,
                                                              YES) firstObject];
        path = [path stringByAppendingPathComponent:@"RKConsole"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        if (![fileManager fileExistsAtPath:path]) {
            [fileManager createDirectoryAtPath:path
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&error];
            if (error) {
                RKLogErr(@"文件夹创建错误: %@",error);
            }
        }
        path = [path stringByAppendingPathComponent:@"RKConsoleLog.log"];
        if ([fileManager fileExistsAtPath:path]) {
            // 删除原文件
            NSError *err;
            [fileManager removeItemAtPath:path error:&err];
            if (err) {
                RKLogErr(@"文件删除错误: %@",err);
            }
        }
        NSData *logData = [((NSMutableAttributedString *)[_logStr copy]).string dataUsingEncoding:NSUTF8StringEncoding];
        [logData writeToFile:path
                  atomically:YES];
        RKLog(@"记录成功!文件路径: %@",path);
    }
}

- (void)pauseAndResumeClick:(BOOL)resume {
    if (resume) {
        // 开始输出日志
        _isPauseLog = NO;
    }else {
        // 暂停输出日志
        _isPauseLog = YES;
    }
}
- (void)showCrashLogClick:(BOOL)show {
    if (show) {
        // 关闭崩溃日志
        self.showCrashLog = NO;
    }else {
        // 显示崩溃日志
        self.showCrashLog = YES;
    }
}

- (void)clearClick {
    // 添除日志
    @synchronized (_logStr) {
        _logStr = [[NSMutableAttributedString alloc] init];
        [_logView showLog:_logStr];
    }
}

#pragma mark -- 打开日志页面
- (void)logControl:(UIButton *)sender {
    
    __weak typeof(self)weakself = self;
    // show the logView and hide the logBtn and window`s cornerRadius to 0 backgroundColor to white
    [UIView animateWithDuration:0.5
                     animations:^{
                         weakself.window.frame = CGRectMake(0, WQMainHeight - WQShowHeight, WQMainWidth, WQShowHeight);
                         weakself.window.layer.cornerRadius = 0;
                         weakself.window.backgroundColor = [UIColor grayColor];
                         weakself.logBtn.hidden = YES;
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             weakself.window.backgroundColor = [UIColor clearColor];
                             weakself.logView.hidden = NO;
                             weakself.isShowLog = YES;
                             [weakself.logView showLog:weakself.logStr];
                         }
                     }];
}

#pragma mark -- 移动手势
- (void)panGesture:(UIPanGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:[[UIApplication sharedApplication] delegate].window];
    CGFloat wWidth = CGRectGetWidth(_window.frame);
    CGFloat wHeight = CGRectGetHeight(_window.frame);
    if (point.x + wWidth/2.0 >= WQMainWidth) {
        point.x = WQMainWidth - wWidth/2.0;
    }
    if (point.x - wWidth/2.0 <= 0) {
        point.x = wWidth/2.0;
    }
    if (point.y + wHeight/2.0 >= WQMainHeight) {
        point.y = WQMainHeight - wHeight/2.0;
    }
    if (point.y - wHeight/2.0 <= 0) {
        point.y = wHeight/2.0;
    }
    switch (sender.state) {
        case UIGestureRecognizerStateEnded:{
            if (WQMainWidth - point.x > point.x) {
                // 靠左
                point.x = wWidth/2.0;
            }else {
                // 靠右
                point.x = WQMainWidth - wWidth/2.0;
            }
            
        }break;
            
        default:{
        }break;
    }
    [UIView animateWithDuration:0.1
                     animations:^{
                         self.window.center = point;
                     }];
}

#pragma mark -- Set 方法
- (void)setConsoleColor:(UIColor *)consoleColor {
    _consoleColor = consoleColor;
    _logView.consoleColor = consoleColor;
}

#pragma mark -- instance
+ (void)destroyInstance
{
    _instance = nil;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

- (id)copyWithZone:(NSZone *)zone
{
    return _instance;
}

- (void)dealloc {
    NSLog(@"%@:----释放了",NSStringFromSelector(_cmd));
}

@end
