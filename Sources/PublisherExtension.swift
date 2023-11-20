//
//  PublisherExtension.swift
//  BlockingPublisher
//
//  Created by Andrii Turkin on 20.11.23.
//

import Foundation
import Combine

extension Publisher {
    func toBlocking(timeout: TimeInterval = 5.0) -> BlockingPublisher<Output, Failure> {
        return BlockingPublisher(self, timeout: timeout)
    }
}
