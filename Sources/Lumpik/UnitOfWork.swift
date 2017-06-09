//
//  UnitOfWork.swift
//  Lumpik
//
//  Created by Namai Satoshi on 2017/03/05.
//
//

import Foundation

public struct UnitOfWork: Codable {
    static var connectionPoolForInternal = AnyConnectablePool(Application.default.connectionPoolForInternal)
    
    public let jid: Jid
    public let workerType: String
    public let args: Data
    public let queue: Queue
    public let createdAt: TimeInterval
    public let enqueuedAt: TimeInterval
    public var retryCount: Int?
    public var retriedAt: TimeInterval?
    public var retryQueue: Queue?
    public var failedAt: TimeInterval?
    public var errorMessage: String?
    public var errorBacktrace: String?
    public let backtrace: ToggleOrLimit?
    public let retry: ToggleOrLimit?
    
    public enum ToggleOrLimit {
        case on
        case off
        case limited(UInt)
    }
    
    enum CodingKeys: String, CodingKey {
        case jid
        case workerType = "class"
        case args
        case queue
        case createdAt = "created_at"
        case enqueuedAt = "enqueued_at"
        case retryCount = "retry_count"
        case retriedAt = "retried_at"
        case retryQueue = "retry_queue"
        case failedAt = "failedAt"
        case errorMessage = "error_message"
        case errorBacktrace = "error_backtrace"
        case backtrace
        case retry
    }
    
    public func requeue() throws {
        try UnitOfWork.connectionPoolForInternal.with { conn in
            try conn.enqueue(self, to: self.queue)
        }
    }
}

extension UnitOfWork {
    var retryLimit: Int {
        guard let retry = retry else { return 25 }
        switch retry {
        case .on:
            return 25
        case .off:
            return 0
        case .limited(let x):
            return Int(x)
        }
    }
}

extension UnitOfWork.ToggleOrLimit: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolValue = try? container.decode(Bool.self) {
            self = boolValue ? .on : .off
        } else if let intValue = try? container.decode(UInt.self) {
            self = .limited(intValue)
        } else {
            throw DecodingError.typeMismatch(
                UnitOfWork.ToggleOrLimit.self, .init(codingPath: [], debugDescription: ""))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .on:
            try container.encode(true)
        case .off:
            try container.encode(false)
        case .limited(let x):
            try container.encode(x)
        }
    }
}
