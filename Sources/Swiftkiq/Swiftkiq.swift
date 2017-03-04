final public class SwiftkiqCore {
    static var host: String = "127.0.0.1"
    static var port: UInt16 = 6379

    enum Control: Error {
        case shutdown
    }
    
    static func makeStore() -> ListStorable {
        return try! RedisStore(host: SwiftkiqCore.host, port: SwiftkiqCore.port)
    }
}
