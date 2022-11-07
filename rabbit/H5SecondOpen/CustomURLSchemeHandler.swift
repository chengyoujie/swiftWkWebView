

import Foundation
import WebKit

@available(iOS 11.0, *)
class CustomURLSchemeHandler: NSObject {
    // MARK: ---------------------------- lazy var ------------------------
    /// http 管理
    lazy var httpSessionManager: AFHTTPSessionManager = {
        let manager = AFHTTPSessionManager()
        manager.requestSerializer = AFHTTPRequestSerializer()
        manager.responseSerializer = AFHTTPResponseSerializer()
        manager.responseSerializer.acceptableContentTypes = Set(arrayLiteral: "text/html", "application/json", "text/json", "text/javascript", "text/plain", "application/javascript", "application/javascript", "application/json", "text/css", "image/svg+xml", "application/font-woff2", "font/woff2", "application/octet-stream", "audio/mpeg", "image/png", "image/jpg", "image/jpeg", "application/x-www-form-urlencoded")
        
        return manager
    }()
    
    // MARK: ---------------------------- var ------------------------
    /// 防止 urlSchemeTask 实例释放了，又给他发消息导致崩溃
    var holdUrlSchemeTasks = [AnyHashable: Bool]()
    /// 资源缓存
    var resourceCache = H5ResourceCache()
    
    // MARK: ---------------------------- life Cycle ------------------------
    deinit {
        print("\(String(describing: self)) 销毁了")
    }
}

// MARK: - privateFunc
extension CustomURLSchemeHandler {
    /// 生成缓存key
    private func creatCacheKey(urlSchemeTask: WKURLSchemeTask) -> String? {
        guard let fileName = urlSchemeTask.request.url?.absoluteString else { return nil }
        guard let extensionName = urlSchemeTask.request.url?.pathExtension else { return nil }
        var result = fileName.md5()
        if extensionName.count == 0 {
            result += ".html"
        } else {
            result += ".\(extensionName)"
        }
        
        return result
    }
}

// MARK: - resource load
extension CustomURLSchemeHandler {
    /// 加载本地资源
    private func loadLocalFile(fileName: String?, urlSchemeTask: WKURLSchemeTask) {
        if fileName == nil && fileName?.count == 0 { return }
        
        // 先从本地中文件中加载
        if resourceCache.contain(forKey: fileName!)  {
            // 缓存命中
            print("缓存命中 \(urlSchemeTask.request.url?.absoluteString ?? "nil")")
            guard let data = resourceCache.data(forKey: fileName!) else {
                print("缓存失效： \(urlSchemeTask.request.url?.absoluteString ?? "nil")")
                requestRomote(fileName: fileName!, urlSchemeTask: urlSchemeTask)
                return
                
            }
            let pathExt = urlSchemeTask.request.url?.pathExtension
//            var data2 = Data()
//            if pathExt == "json"{
//                let str = String(data: data, encoding: .utf8)
//                print(str)
//            }
            let mimeType = String.mimeType(pathExtension: urlSchemeTask.request.url?.pathExtension)
//            print("fileName : \(fileName)  mimeType: \(mimeType)")
            resendRequset(urlSchemeTask: urlSchemeTask, mineType: mimeType, requestData: data)
        } else {
//            print("没有缓存!!!!")
            requestRomote(fileName: fileName!, urlSchemeTask: urlSchemeTask)
        }
    }
    
    /// 加载远程资源
    func requestRomote(fileName: String, urlSchemeTask: WKURLSchemeTask) {
        // 没有缓存,替换url，重新加载
        guard let urlString = urlSchemeTask.request.url?.absoluteString else { return }
//        print("开始重新发送网络请求 \(urlString)" )
        // 替换成https请求
        httpSessionManager.get(urlString, parameters: nil, progress: nil, success: { (dask, reponseObject) in
            // urlSchemeTask 是否提前结束，结束了调用实例方法会崩溃
            if let isValid = self.holdUrlSchemeTasks[urlSchemeTask.description] {
                if !isValid {
                    return
                }
            }
//            if urlString.contains("json") {
                print("loading \(urlString)")
//            }
//            print("HTTP   back \(urlString)")
            
            
            guard let response = dask.response, let data = reponseObject as? Data else {
                print(" NET ERROR \(urlString) ")
                return }
            
//            print("response  URL:\(response.url) mineType: \(response.mimeType)  encoding:\(response.textEncodingName) data:\(data.count) other:\(response.description)")
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
            self.resourceCache.setData(data: data, forKey: fileName)
//            guard let accept = urlSchemeTask.request.allHTTPHeaderFields?["Accept"] else { return }
//            if !(accept.count > "image".count && accept.contains("image")) {
//                // 图片不下载
//                self.resourceCache.setData(data: data, forKey: fileName)
//            }
            
        }) { (_, error) in
            print("Load ERROR : \(error)")
            // urlSchemeTask 是否提前结束，结束了调用实例方法会崩溃
            if let isValid = self.holdUrlSchemeTasks[urlSchemeTask.description] {
                if !isValid {
                    return
                }
            }
            
            // 错误处理
            urlSchemeTask.didFailWithError(error)
        }
    }
    
    /// 重新发送请求
    ///
    /// - Parameters:
    ///   - urlSchemeTask: <#urlSchemeTask description#>
    ///   - mineType: <#mineType description#>
    ///   - requestData: <#requestData description#>
    func resendRequset(urlSchemeTask: WKURLSchemeTask, mineType: String?, requestData: Data) {
        guard let url = urlSchemeTask.request.url else { return }
        if let isValid = holdUrlSchemeTasks[urlSchemeTask.description] {
            if !isValid {
                return
            }
        }
        let mineT = mineType ?? "text/html"
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "", headerFields: ["Access-Control-Allow-Origin":"*"])!
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(requestData)
        urlSchemeTask.didFinish()
    }
}

// MARK: - WKURLSchemeHandler
extension CustomURLSchemeHandler: WKURLSchemeHandler {
    // 自定义拦截请求开始
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        holdUrlSchemeTasks[urlSchemeTask.description] = true
        let headers = urlSchemeTask.request.allHTTPHeaderFields
        guard let requestUrlString = urlSchemeTask.request.url?.absoluteString else { return }
        let pathExt = urlSchemeTask.request.url?.pathExtension
//        if pathExt == "png" {
//
//        }else if pathExt == "jpg"{
//
//        }else if pathExt == "json"{
//
//        }else {
        guard let cacheKey = self.creatCacheKey(urlSchemeTask: urlSchemeTask)
        else {
            print ("\(requestUrlString) MD5 --ERROR--")
            return
        }
//        print ("\(requestUrlString) MD5 \(cacheKey)")
        if resourceCache.useCache == false ||  pathExt == "php" || pathExt == "html" {
            requestRomote(fileName: cacheKey, urlSchemeTask: urlSchemeTask)
        }else{
            loadLocalFile(fileName: cacheKey, urlSchemeTask: urlSchemeTask)
        }
//
//        }
//        guard let accept = headers?["Accept"] else {
//            print(" url: \(requestUrlString) not Accept ")
//            return
//        }
//        if accept.count >= "text".count && accept.contains("text/html") {
//            // html 拦截
//            print("html = \(String(describing: requestUrlString))  ext \(pathExt)")
//            loadLocalFile(fileName: creatCacheKey(urlSchemeTask: urlSchemeTask), urlSchemeTask: urlSchemeTask)
//        }else
//        if accept.count >= "image".count && accept.contains("image") {//图片文件
//           // 图片
//           print("image = \(String(describing: requestUrlString))")
//           guard let originUrlString = urlSchemeTask.request.url?.absoluteString else { return }
//
//           SDWebImageManager.shared.loadImage(with: URL(string: originUrlString), options: SDWebImageOptions.retryFailed, progress: nil) { (image, data, error, type, _, _) in
//               if let image = image {
////                   if requestUrlString.isJpeFile() {
//                       print("jpg imgage \(originUrlString)")
//                       guard let jpgData = image.jpegData(compressionQuality: 1) else { return }
//                       self.resendRequset(urlSchemeTask: urlSchemeTask, mineType: "image/jpeg", requestData: jpgData)
////                   }else{
////                       print("png image \(originUrlString)")
////                       guard let pngData = image.pngData() else { return }
////                       self.resendRequset(urlSchemeTask: urlSchemeTask, mineType: "image/png", requestData: pngData)
////                   }
//               } else {
//                   self.loadLocalFile(fileName: self.creatCacheKey(urlSchemeTask: urlSchemeTask), urlSchemeTask: urlSchemeTask)
//               }
//           }
//       }
//        else if (pathExt == "json") {//json文件
//            print("json = \(String(describing: requestUrlString))")
//            loadLocalFile(fileName: creatCacheKey(urlSchemeTask: urlSchemeTask), urlSchemeTask: urlSchemeTask)
//       }
//        else {// other resources
//            print("other resources = \(String(describing: requestUrlString))")
//            guard let cacheKey = self.creatCacheKey(urlSchemeTask: urlSchemeTask) else { return }
//            requestRomote(fileName: cacheKey, urlSchemeTask: urlSchemeTask)
//       }
    }
    
    /// 自定义请求结束时调用
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        holdUrlSchemeTasks[urlSchemeTask.description] = false
    }
}
