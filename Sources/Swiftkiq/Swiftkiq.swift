final public class SwiftkiqCore {
    static var host: String = "127.0.0.1"
    static var port: UInt16 = 6379
    
    static let store: ListStorable = try! RedisStore(host: host, port: port)
    
    enum Control: Error {
        case shutdown
    }
}
