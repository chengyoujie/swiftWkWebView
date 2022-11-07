
import Foundation

/// h5 页面资源缓存
class H5ResourceCache: NSObject {
    /// 内存缓存大小：50M
    private let kMemoryCacheCostLimit: UInt = 50 * 1024 * 1024
    /// 磁盘文件缓存大小： 300M
    private let kDiskCacheCostLimit: UInt = 300 * 1024 * 1024
    /// 磁盘文件缓存时长：120 day
    private let kDiskCacheAgeLimit: TimeInterval = 120 * 24 *  60 * 60
    
    private var memoryCache: MemoryCache
    private var diskCache: DiskFileCache
    /// 
    public var useCache: Bool = true
    
    override init() {
        memoryCache = MemoryCache.shared
        memoryCache.costLimit = kMemoryCacheCostLimit
            
        diskCache = DiskFileCache(cacheDirectoryName: "H5ResourceCache")
        diskCache.costLimit = kDiskCacheCostLimit
        diskCache.ageLimit = kDiskCacheAgeLimit
        
        super.init()
    }
    
    func contain(forKey key: String) -> Bool {
        return memoryCache.contain(forKey: key) || diskCache.contain(forKey: key)
    }
    
    func setData(data: Data, forKey key: String) {
//        guard let dataString = String(data: data, encoding: .utf8) else { return }
        memoryCache.setObject(data, forKey: key, withCost: UInt(data.count))
        diskCache.setObject(data, forKey: key, withCost: UInt(data.count))
//        diskCache.setObject(dataString.data(using: .utf8)!, forKey: key, withCost: UInt(data.count))
    }
    
    func data(forKey key: String) -> Data? {
        if let data = memoryCache.object(forKey: key) {
            print("这是内存缓存")
            return data as? Data
        } else {
            guard let data = diskCache.object(forKey: key) else { return nil}
            memoryCache.setObject(data, forKey: key, withCost: UInt(data.count))
            print("这是磁盘缓存")
            return data
        }
    }
    
    func removeData(forKey key: String) {
        memoryCache.removeObject(forKey: key)
        diskCache.removeObject(forKey: key)
    }
    
    func removeAll() {
        memoryCache.removeAllObject()
        diskCache.removeAllObject()
    }
}
