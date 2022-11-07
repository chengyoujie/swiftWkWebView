//
//  WKWebViewSchemeExtendsion.m
//  TestWKWebView
//
//  Created by cyj on 2022/10/18.
//

#import "SPSDKBridgHeader.h"
#import <objc/runtime.h>

@implementation WKWebView (SchemeExtersion)
    
+ (void)load {
    method_exchangeImplementations(class_getClassMethod(self, @selector(handlesURLScheme:)), class_getClassMethod(self, @selector(__handlesURLScheme:)));
}

+ (BOOL)__handlesURLScheme:(NSString *)urlScheme {
    if([urlScheme isEqualToString:@"http"] || [urlScheme isEqualToString:@"https"]) {
        return NO;
    }
    return [self __handlesURLScheme: urlScheme];
}
    
@end

