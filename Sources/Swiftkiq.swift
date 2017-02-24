public protocol Job {
    func serialized() -> [Any]
    func deserialize(_: [Any]) -> Self
}

public protocol Queue {
    var string: String { get }
}

public protocol ListStorable {
    func enqueue(_ job: Job, to queue: Queue)
    func dequeue(_ queue: Queue) -> Job?
}

public protocol Swiftkiq {
    var redis: ListStorable { get }
    func enqueue(_ job: Job, to: Queue)
}

public protocol Worker {
    associatedtype Argument: Job

    static var client: Swiftkiq { get }
    static var queue: Queue { get }
    static var retry: Int { get }

    static func performAsync(_ job: Argument, to queue: Queue)
    func perform(_ job: Argument) -> ()
}

enum DefaultQueue: String, Queue {
    case `default`
    public var string: String {
        return rawValue
    }
}

extension Worker {
    public static var client: Swiftkiq {
        return SwiftkiqClient.default
    }

    public static var queue: Queue {
        return DefaultQueue.default
    }

    public static var retry: Int {
        return 25
    }

    public static func performAsync(_ job: Argument, to queue: Queue = Self.queue) {
        Self.client.enqueue(job, to: queue)
    }
}

class MockStore: ListStorable {
    var all = Dictionary<String, Array<Job>>()

    public func enqueue(_ job: Job, to queue: Queue) {
        if var list = all[queue.string] {
            list.append(job)
        } else {
            var list = Array<Job>()
            list.append(job)
            all[queue.string] = list
        }
    }

    public func dequeue(_ queue: Queue) -> Job? {
        return all[queue.string]?.removeFirst()
    }
}

public struct SwiftkiqClient: Swiftkiq {
    public let redis: ListStorable

    static var `default`: Swiftkiq {
        return SwiftkiqClient(redis: MockStore())
    }

    init(redis: ListStorable) {
        self.redis = redis
    }

    public func enqueue(_ job: Job, to queue: Queue) {
        redis.enqueue(job, to: queue)
    }
}
