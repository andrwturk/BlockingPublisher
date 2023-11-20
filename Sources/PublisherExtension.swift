//
//  PublisherExtension.swift
//  BlockingPublisher
//
//  Created by Andrii Turkin on 20.11.23.
//

import Foundation
import Combine


public extension Publisher {

    /// Blocks the thread and waits for it to be finished or `timeout` to end
    /// - Parameter timeout: timeout in seconds
    /// - Returns: `BlockingPublisher` instance
    ///
    /// Usage:
    ///     let item = try? somePublisher.toBlocking().first()
    ///     expect(item).to(equal("VALUE"))
    ///
    func toBlocking(timeout: TimeInterval = 5.0) -> BlockingPublisher<Output, Failure> {
        return BlockingPublisher(self, timeout: timeout)
    }
}
