//
//  ViewController.m
//  xaizaizip
//
//  Created by wyzw on 2018/3/16.
//  Copyright © 2018年 wyzw. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"
#import "SSZipArchive.h"
#import <WebKit/WebKit.h>

@interface ViewController ()<UIWebViewDelegate,WKUIDelegate,WKNavigationDelegate>
@property(nonatomic,copy)NSString * urlstr;
@property(nonatomic,copy)NSString * decodestr;
@property(nonatomic,strong)WKWebView * webView;

//运行此项目时  需要下载一个zip 然后才可以进行解压展示  没有测试环境需要的zip链接 可以自己搭建个本地服务器 自己放一个压缩包放上去测试 （搭建服务器链接网址:https://www.jianshu.com/p/ad0833f4845a）
//项目简书地址：https://www.jianshu.com/p/c40e39fe600e
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addbtn];
    
}
-(void)btnlcick:(UIButton*)btn{
    switch (btn.tag) {
        case 666://下载
            [self rquestZipArchivePath:@"http://192.168.1.35:8080/dist.zip" andHtmlVersion:@"666"];
            break;
        case 667://解压
            [self releaseZipFilesWithUnzipFileAtPath:self.urlstr Destination:self.decodestr];
            
            break;
        case 668://展示
            [self showWkwebview];
            break;
            
        default:
            break;
    }
    
}
-(void)showWkwebview{
    
    //    /初始化一个WKWebViewConfiguration对象
    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    //初始化偏好设置属性：preferences
    config.preferences = [WKPreferences new];
    //The minimum font size in points default is 0;
    config.preferences.minimumFontSize = 10;
    //是否支持JavaScript
    config.preferences.javaScriptEnabled = YES;
    //不通过用户交互，是否可以打开窗口
    config.preferences.javaScriptCanOpenWindowsAutomatically = YES;
    
    self.webView=[[WKWebView alloc]initWithFrame:self.view.bounds configuration:config];
    _webView.navigationDelegate=self;
    _webView.UIDelegate = self;
    
    //
    NSArray *documentArray = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *path = [[documentArray lastObject] stringByAppendingPathComponent:@"Preferences"];
/*   判断文件是否存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isexit = [fileManager fileExistsAtPath:urlStr];
*/
/*
    NSURL *url=[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/dist/index.html",path]];
    NSString *urlStr = [url absoluteString];
    urlStr = [urlStr stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:urlStr]]];
 */
    
//此处wkwebview加载方式有可能会变（加载本地路径和网址不一样 模拟器真机也不一样 建议用真机调试）
    NSString * tempurl = [NSString stringWithFormat:@"file://%@/dist/666.html",path];
    NSURL * accessUrl = [[NSURL URLWithString:tempurl] URLByDeletingLastPathComponent];
    [self.webView loadFileURL:[NSURL URLWithString:tempurl] allowingReadAccessToURL:accessUrl];
    
    [self.view addSubview:self.webView];
    
}

-(void)rquestZipArchivePath:(NSString *)pathUrl andHtmlVersion:(NSString *)version{
    //远程地址
    NSURL *URL = [NSURL URLWithString:pathUrl];
    //默认配置
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    //请求
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURLSessionDownloadTask * downloadTask =[manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        double curr=(double)downloadProgress.completedUnitCount;
        double total=(double)downloadProgress.totalUnitCount;
        NSLog(@"下载进度==%.2f",curr/total);
        
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        //- block的返回值, 要求返回一个URL, 返回的这个URL就是文件的位置的路径
        
        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        
        //再次之前先删除本地文件夹里面相同的文件夹
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *contents = [fileManager contentsOfDirectoryAtPath:cachesPath error:NULL];
        NSEnumerator *e = [contents objectEnumerator];
        NSString *filename;
        NSString *extension = @"zip";
        while ((filename = [e nextObject])) {
            
            if ([[filename pathExtension] isEqualToString:extension]) {
                
                [fileManager removeItemAtPath:[cachesPath stringByAppendingPathComponent:filename] error:NULL];
            }
        }
        NSString *path = [cachesPath stringByAppendingPathComponent:response.suggestedFilename];
        return [NSURL fileURLWithPath:path];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        //设置下载完成操作
        
        // filePath就是你下载文件的位置，你可以解压，也可以直接拿来使用
        NSString *htmlFilePath = [filePath path];// 将NSURL转成NSString
        NSArray *documentArray =  NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *path = [[documentArray lastObject] stringByAppendingPathComponent:@"Preferences"];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@/html",path] error:nil];
        self.urlstr=htmlFilePath;
        self.decodestr=path;
    }];
    
    [downloadTask resume];
}
#pragma mark 解压
- (void)releaseZipFilesWithUnzipFileAtPath:(NSString *)zipPath Destination:(NSString *)unzipPath{
    //    NSLog(@"%@,%@",zipPath,unzipPath);
    NSError *error;
    
    if ([SSZipArchive unzipFileAtPath:zipPath toDestination:unzipPath overwrite:YES password:nil error:&error delegate:self]) {
        NSLog(@"success");
    }
    else{
        NSLog(@"%@",error);
    }
    // 压缩包的全路径(包括文件名)
    //    NSString *destinationPath = zipPath;
    // 目标路径,
    NSString *destinationPath = unzipPath;
    // 解压, 返回值代表是否解压完成
    Boolean b = [SSZipArchive unzipFileAtPath:zipPath toDestination:destinationPath];
    
    //    ------------ 带回调的解压    ------------
    Boolean b1 = [SSZipArchive unzipFileAtPath:zipPath toDestination:destinationPath progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
        // entry : 解压出来的文件名
        //entryNumber : 第几个, 从1开始
        //total : 总共几个
        NSLog(@"progressHandler:%@, entryNumber:%ld, total:%ld  names:%@", entry, entryNumber, total,destinationPath);
    } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nullable error) {
        //path : 被解压的压缩吧全路径
        //succeeded 是否成功
        // error 错误信息
        NSLog(@"completionHandler:%@, , succeeded:%d, error:%@", path, succeeded, error);
    }];
    
}

#pragma mark - SSZipArchiveDelegate
- (void)zipArchiveWillUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo {
    NSLog(@"将要解压%d",zipInfo.number_entry);
    
}
- (void)zipArchiveDidUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo unzippedPath:(NSString *)unzippedPat uniqueId:(NSString *)uniqueId {
    NSLog(@"解压完成！");
}
-(void)addbtn{
    NSArray * arr =@[@"下载",@"解压",@"展示html"];
    for (int i=0; i<3; i++) {
        UIButton* btn =[[UIButton alloc]init];
        btn.backgroundColor=[UIColor orangeColor];
        btn.frame=CGRectMake(120*i+30, 200, 100, 100);
        [btn setTitle:arr[i] forState:UIControlStateNormal];
        btn.tag=666+i;
        [btn addTarget:self action:@selector(btnlcick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
    
}

//#pragma mark - WKUIDelegate
//// 创建一个新的WebView
////- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{
////    return [[WKWebView alloc]init];
////}
//// 输入框
//- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler{
//    completionHandler(@"http");
//}
//// 确认框
//- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler{
//    completionHandler(YES);
//}
//// 警告框
//- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
//    NSLog(@"%@",message);
//    completionHandler();
//}
//
//
//#pragma mark - WKNavigationDelegate
//// 页面开始加载时调用
//- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
//
//}
//// 当内容开始返回时调用
//- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
//
//}
//// 页面加载完成之后调用
//- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
//
//}
//// 页面加载失败时调用
//- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation{
//
//}
//// 接收到服务器跳转请求之后调用
//- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{
//
//}
//// 在收到响应后，决定是否跳转
//- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
//
//    NSLog(@"%@",navigationResponse.response.URL.absoluteString);
//    //允许跳转
//    decisionHandler(WKNavigationResponsePolicyAllow);
//    //不允许跳转
//    //decisionHandler(WKNavigationResponsePolicyCancel);
//}
//// 在发送请求之前，决定是否跳转
//- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
//
//    NSLog(@"%@",navigationAction.request.URL.absoluteString);
//    //允许跳转
//    decisionHandler(WKNavigationActionPolicyAllow);
//    //不允许跳转
//    //decisionHandler(WKNavigationActionPolicyCancel);
//}
//
//
//


@end
