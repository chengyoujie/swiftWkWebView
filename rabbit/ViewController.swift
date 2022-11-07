//
//  ViewController.swift
//  rabbit
//
//  Created by cyj on 2022/9/18.
//

import UIKit
import WebKit

private let GameLoginoutURL = "https://www.baidu.com"
private let GameLoginURL = "https://www.baidu.com"

class ViewController: UIViewController {
    
    var adId: Int = 0
    
    lazy var progressLine: UIProgressView = {
        let line = UIProgressView(frame: CGRect.zero)
        line.backgroundColor = UIColor.white
        line.progressTintColor = UIColor.gray
        line.isHidden = true
        return line
    }()
    
    lazy var urlSchemeHandler: CustomURLSchemeHandler  = {
        let urlSchemeHandler = CustomURLSchemeHandler()
        return urlSchemeHandler
    }()
    
    lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration.init()
        if config.urlSchemeHandler(forURLScheme: "https") == nil  {
            config.setURLSchemeHandler(urlSchemeHandler, forURLScheme: "http")
            config.setURLSchemeHandler(urlSchemeHandler, forURLScheme: "https")
        }
        config.mediaTypesRequiringUserActionForPlayback = .all
        config.allowsInlineMediaPlayback = true
        let wkwebView = WKWebView(frame: view.bounds, configuration: config)//WebViewReusePool.shared.getReusedWebView(ForHolder: self)!
        wkwebView.navigationDelegate = self
        wkwebView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)

        return wkwebView
    }()
    
    var userData: SPUserData?;
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if webView.title == nil {// 白屏
            webView.reload()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("APP初始化")
        
        webView.frame = view.bounds
        view.addSubview(webView)
        progressLine.frame = CGRect(x: 0, y: view.bounds.height-1, width: view.bounds.width, height: 1)
        view.addSubview(progressLine)
        view.bringSubviewToFront(progressLine)
        
        
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.allowsAirPlayForMediaPlayback = true
        webView.configuration.allowsPictureInPictureMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = .all
        
        webView.uiDelegate = self
        webView.uiDelegate = self
        webView.scrollView.delegate = self
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        initJS()
        refushWebView()
        initSDK()
    }
    
    deinit {
//       webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
//        WebViewReusePool.shared.recycleReusedWebView(webView as? ReuseWebView)
        print("webView 销毁了!!!")
    }
    
    
    // 观察者
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let value = change?[NSKeyValueChangeKey.newKey] as! NSNumber
        progressLine.progress = value.floatValue
    }
}

//cache
extension ViewController {
    
    func showCacheSize(){
        //磁盘容量大小
        
        var total: UInt = 0
        guard let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last else { return  }
        let fileCacheDir = cacheDir.appendingPathComponent("H5ResourceCache")
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: fileCacheDir.path)
            for file in files {
                let fileUrl = fileCacheDir.appendingPathComponent(file)
                if let attributes = try? FileManager.default.attributesOfItem(atPath: fileUrl.path) {
                    total += (attributes[FileAttributeKey.size] as? UInt) ?? 0
                }
            }
        } catch {
            
        }
        
        let cacheSize = String(format: "%.2f", Double(total)/1024/1024)
        print("磁盘总缓存大小：\(cacheSize)MB")
    }
}


//sdk
extension ViewController {
    //初始化
    func initSDK() {
        
    }
    
    func toLogin() {
        print("pre loading")
        
    }
    
    func refushWebView(){
        
        var gameurl:String = GameLoginoutURL
        if let udata = userData
        {
            // let userName = udata.username as NSString
            // let userToken = udata.token as NSString
            // let loginTimeStamp = udata.timestamp as NSString
            // print("登陆成功 userName=\(userName)  userToken=\(userToken)  loginTimeStamp=\(loginTimeStamp)")
            // gameurl = GameLoginURL+"?username=\(userName)&token=\(userToken)&timestamp=\(loginTimeStamp)"
            
        }
        let gameNSURL = URL(string: gameurl)!
        print("game URL \(gameurl)")
        self.webView.load(URLRequest(url: gameNSURL))
    }
    
    func toPay(iosProductId: String, productName: String, amount: String, ext: String) {
        print("-- sdk pay--")
        
    }
    
    func toLoginout() {
        
    }
    
    
    func toGetRelaNameInfo(){
        SPSDK.instance().userCertificationInfo { success, data in
            print(" 实名认证信息： \(data ?? "")")
            let jsonData = try? JSONSerialization.data(withJSONObject: data ?? {}, options: [])
            let jsonStr = String(data: jsonData ?? Data(), encoding: String.Encoding.utf8)
            self.callJs(type: "realnameInfo", message: (jsonStr ?? ""))
        }
    }
    
    func toShowAd(id: Int){
        self.adId = id
    }
    
}



//js
extension ViewController: WKScriptMessageHandler {
    
    func initJS(){
        
        webView.configuration.userContentController.add(self, name: "toPay")
        webView.configuration.userContentController.add(self, name: "toReport")
        webView.configuration.userContentController.add(self, name: "toLogin")
        webView.configuration.userContentController.add(self, name: "toLoginout")
        webView.configuration.userContentController.add(self, name: "toGetRelaNameInfo")
        webView.configuration.userContentController.add(self, name: "setInterceptHttp")
        webView.configuration.userContentController.add(self, name: "setUseLocalCache")
        webView.configuration.userContentController.add(self, name: "toClearCache")
        webView.configuration.userContentController.add(self, name: "toShowAd")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("message = \(message)")
        print("message.name = \(message.name)")
        print("message.body = \(message.body)")
        if message.name == "toPay" {//充值
            if let dic = message.body as? NSDictionary {
                let iosProductId: String = (dic["iosProductId"] as AnyObject).description
                let productName: String = (dic["productName"] as AnyObject).description
                let amount: String = (dic["amount"] as AnyObject).description
                let ext: String = (dic["ext"] as AnyObject).description
                toPay(iosProductId: iosProductId, productName: productName, amount: amount, ext: ext)
            }else{
                print("充值失败， 参数不正确")
            }
        }else if message.name == "toLogin" {
            toLogin()
        }else if message.name == "toLoginout" {//登出
            toLoginout()
        }else if message.name == "toGetRelaNameInfo" {
            toGetRelaNameInfo()
        }else if message.name == "setInterceptHttp" {
//            let config = webView.configuration;
//            if  message.body as! Bool == true {
//                if (config.urlSchemeHandler(forURLScheme: "https") == nil)   {
//                    config.setURLSchemeHandler(urlSchemeHandler, forURLScheme: "http")
//                    config.setURLSchemeHandler(urlSchemeHandler, forURLScheme: "https")
//                }
//            }else{
//                if (config.urlSchemeHandler(forURLScheme: "https") != nil)   {
//
//                    config.setURLSchemeHandler(nil, forURLScheme: "http")
//                    config.setURLSchemeHandler(nil, forURLScheme: "https")
//                }
//            }
        }else if message.name == "setUseLocalCache" {
            if message.body as! Bool == true {
                urlSchemeHandler.resourceCache.useCache = true
            }else{
                urlSchemeHandler.resourceCache.useCache = false
            }
        }else if message.name == "toClearCache" {
            urlSchemeHandler.resourceCache.removeAll()
        }else if message.name == "toShowAd" {
            toShowAd(id: message.body as! Int)
        }
        
    }
    
    func callJs(type: String, message: String){
        webView.evaluateJavaScript("sdkCallBack('\(type)' , '\(message)')")
    }
    
    func callJs(type: String, data:Dictionary<AnyHashable, Any>){
        if !JSONSerialization.isValidJSONObject(data)  {
            print("callJs  无法解析出 JSON")
            return
        }
        guard let data = try? JSONSerialization.data(withJSONObject: data) else{
            print("callJs  无法解析出 JSON")
            return
        }
        let jsonStr = String(data: data, encoding: .utf8)
        guard let str = jsonStr else {
            print("callJs Error String is nil ")
            return
        }
        callJs(type: type, message: str)
    }
    
}

extension ViewController: WKUIDelegate{
    //alert()
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertViewController = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alertViewController.addAction(UIAlertAction(title: "确认", style: .default, handler: { (action) in
            completionHandler()
        }))
        print("alert message=\(message)")
        self.present(alertViewController, animated: true)
    }
}

// MARK: - WKNavigationDelegate
extension ViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressLine.isHidden = false
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressLine.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print(error)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(WKNavigationActionPolicy.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(WKNavigationResponsePolicy.allow)
    }
    
//     白屏
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }
}

extension ViewController: UIScrollViewDelegate {
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollView.panGestureRecognizer.isEnabled = false
    }
}
