/*
 * Copyright 2020 Square Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#if canImport(UIKit)

    import XCTest

    import ReactiveSwift
    import Workflow
    @testable import WorkflowUI

    class DescribedViewControllerTests: XCTestCase {
        // MARK: - Tests

        func test_init() {
            // Given
            let screen = TestScreen.counter(0)

            // When
            let describedViewController = DescribedViewController(screen: screen, environment: .empty)

            // Then
            guard
                let content = describedViewController.content as? CounterViewController
            else {
                XCTFail("Expected a \(String(reflecting: CounterViewController.self)), but got:  \(describedViewController.content)")
                return
            }

            XCTAssertEqual(content.count, 0)
            XCTAssertFalse(describedViewController.isViewLoaded)
            XCTAssertFalse(content.isViewLoaded)
            XCTAssertNil(content.parent)
        }

        func test_viewDidLoad() {
            // Given
            let screen = TestScreen.counter(0)
            let describedViewController = DescribedViewController(screen: screen, environment: .empty)

            // When
            _ = describedViewController.view

            // Then
            XCTAssertEqual(describedViewController.content.parent, describedViewController)
            XCTAssertNotNil(describedViewController.content.viewIfLoaded?.superview)
        }

        func test_update_toCompatibleDescription_beforeViewLoads() {
            // Given
            let screenA = TestScreen.counter(0)
            let screenB = TestScreen.counter(1)

            let describedViewController = DescribedViewController(screen: screenA, environment: .empty)
            let initialChildViewController = describedViewController.content

            // When
            describedViewController.update(screen: screenB, environment: .empty)

            // Then
            XCTAssertEqual(initialChildViewController, describedViewController.content)
            XCTAssertEqual((describedViewController.content as? CounterViewController)?.count, 1)
            XCTAssertFalse(describedViewController.isViewLoaded)
            XCTAssertFalse(describedViewController.content.isViewLoaded)
            XCTAssertNil(describedViewController.content.parent)
        }

        func test_update_toCompatibleDescription_afterViewLoads() {
            // Given
            let screenA = TestScreen.counter(0)
            let screenB = TestScreen.counter(1)

            let describedViewController = DescribedViewController(screen: screenA, environment: .empty)
            let initialChildViewController = describedViewController.content

            // When
            _ = describedViewController.view
            describedViewController.update(screen: screenB, environment: .empty)

            // Then
            XCTAssertEqual(initialChildViewController, describedViewController.content)
            XCTAssertEqual((describedViewController.content as? CounterViewController)?.count, 1)
        }

        func test_update_toIncompatibleDescription_beforeViewLoads() {
            // Given
            let screenA = TestScreen.counter(0)
            let screenB = TestScreen.message("Test")

            let describedViewController = DescribedViewController(screen: screenA, environment: .empty)
            let initialChildViewController = describedViewController.content

            // When
            describedViewController.update(screen: screenB, environment: .empty)

            // Then
            XCTAssertNotEqual(initialChildViewController, describedViewController.content)
            XCTAssertEqual((describedViewController.content as? MessageViewController)?.message, "Test")
            XCTAssertFalse(describedViewController.isViewLoaded)
            XCTAssertFalse(describedViewController.content.isViewLoaded)
            XCTAssertNil(describedViewController.content.parent)
        }

        func test_update_toIncompatibleDescription_afterViewLoads() {
            // Given
            let screenA = TestScreen.counter(0)
            let screenB = TestScreen.message("Test")

            let describedViewController = DescribedViewController(screen: screenA, environment: .empty)
            let initialChildViewController = describedViewController.content

            // When
            _ = describedViewController.view
            describedViewController.update(screen: screenB, environment: .empty)

            // Then
            XCTAssertNotEqual(initialChildViewController, describedViewController.content)
            XCTAssertEqual((describedViewController.content as? MessageViewController)?.message, "Test")
            XCTAssertNil(initialChildViewController.parent)
            XCTAssertEqual(describedViewController.content.parent, describedViewController)
            XCTAssertNil(initialChildViewController.viewIfLoaded?.superview)
            XCTAssertNotNil(describedViewController.content.viewIfLoaded?.superview)
        }

        func test_childViewControllerFor() {
            // Given
            let screen = TestScreen.counter(0)

            let describedViewController = DescribedViewController(screen: screen, environment: .empty)
            let content = describedViewController.content

            // When, Then
            XCTAssertEqual(describedViewController.childForStatusBarStyle, content)
            XCTAssertEqual(describedViewController.childForStatusBarHidden, content)
            XCTAssertEqual(describedViewController.childForHomeIndicatorAutoHidden, content)
            XCTAssertEqual(describedViewController.childForScreenEdgesDeferringSystemGestures, content)
            XCTAssertEqual(describedViewController.supportedInterfaceOrientations, content.supportedInterfaceOrientations)
        }

        func test_childViewControllerFor_afterIncompatibleUpdate() {
            // Given
            let screenA = TestScreen.counter(0)
            let screenB = TestScreen.message("Test")

            let describedViewController = DescribedViewController(screen: screenA, environment: .empty)
            let initialChildViewController = describedViewController.content

            describedViewController.update(screen: screenB, environment: .empty)
            let content = describedViewController.content

            // When, Then
            XCTAssertNotEqual(initialChildViewController, content)
            XCTAssertEqual(describedViewController.childForStatusBarStyle, content)
            XCTAssertEqual(describedViewController.childForStatusBarHidden, content)
            XCTAssertEqual(describedViewController.childForHomeIndicatorAutoHidden, content)
            XCTAssertEqual(describedViewController.childForScreenEdgesDeferringSystemGestures, content)
            XCTAssertEqual(describedViewController.supportedInterfaceOrientations, content.supportedInterfaceOrientations)
        }

        func test_preferredContentSizeDidChange() {
            // Given
            let screenA = TestScreen.counter(1)
            let screenB = TestScreen.counter(2)

            let describedViewController = DescribedViewController(screen: screenA, environment: .empty)
            let containerViewController = ContainerViewController(describedViewController: describedViewController)

            // When
            let expectation = self.expectation(description: "did observe size changes")
            expectation.expectedFulfillmentCount = 2

            var observedSizes: [CGSize] = []
            let disposable = containerViewController.preferredContentSizeSignal.observeValues {
                observedSizes.append($0)
                expectation.fulfill()
            }

            defer { disposable?.dispose() }

            _ = containerViewController.view
            describedViewController.update(screen: screenB, environment: .empty)

            // Then
            let expectedSizes = [CGSize(width: 10, height: 0), CGSize(width: 20, height: 0)]
            waitForExpectations(timeout: 1, handler: nil)
            XCTAssertEqual(observedSizes, expectedSizes)
        }

        func test_preferredContentSizeDidChange_afterIncompatibleUpdate() {
            // Given
            let screenA = TestScreen.counter(1)
            let screenB = TestScreen.message("Test")
            let screenC = TestScreen.message("Testing")

            let describedViewController = DescribedViewController(screen: screenA, environment: .empty)
            let containerViewController = ContainerViewController(describedViewController: describedViewController)

            // When
            let expectation = self.expectation(description: "did observe size changes")
            expectation.expectedFulfillmentCount = 3

            var observedSizes: [CGSize] = []
            let disposable = containerViewController.preferredContentSizeSignal.observeValues {
                observedSizes.append($0)
                expectation.fulfill()
            }

            defer { disposable?.dispose() }

            _ = containerViewController.view
            describedViewController.update(screen: screenB, environment: .empty)
            describedViewController.update(screen: screenC, environment: .empty)

            // Then
            let expectedSizes = [
                CGSize(width: 10, height: 0),
                CGSize(width: 40, height: 0),
                CGSize(width: 70, height: 0),
            ]

            waitForExpectations(timeout: 1, handler: nil)
            XCTAssertEqual(observedSizes, expectedSizes)
        }
    }

    // MARK: - Helper Types

    fileprivate enum TestScreen: Screen, Equatable {
        case counter(Int)
        case message(String)

        func viewControllerDescription(environment: ViewEnvironment) -> ViewControllerDescription {
            switch self {
            case .counter(let count):
                return ViewControllerDescription(
                    build: { CounterViewController(count: count) },
                    update: { $0.count = count }
                )

            case .message(let message):
                return ViewControllerDescription(
                    build: { MessageViewController(message: message) },
                    update: { $0.message = message }
                )
            }
        }
    }

    fileprivate class ContainerViewController: UIViewController {
        let describedViewController: DescribedViewController

        var preferredContentSizeSignal: Signal<CGSize, Never> { return signal.skipRepeats() }

        private let (signal, sink) = Signal<CGSize, Never>.pipe()

        init(describedViewController: DescribedViewController) {
            self.describedViewController = describedViewController
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable) required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            addChild(describedViewController)
            describedViewController.view.frame = view.bounds
            describedViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(describedViewController.view)
            describedViewController.didMove(toParent: self)
        }

        override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
            super.preferredContentSizeDidChange(forChildContentContainer: container)

            guard container === describedViewController else { return }

            sink.send(value: container.preferredContentSize)
        }
    }

    fileprivate class CounterViewController: UIViewController {
        var count: Int {
            didSet {
                preferredContentSize.width = CGFloat(count * 10)
            }
        }

        init(count: Int) {
            self.count = count
            super.init(nibName: nil, bundle: nil)
            preferredContentSize.width = CGFloat(count * 10)
        }

        @available(*, unavailable) required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    fileprivate class MessageViewController: UIViewController {
        var message: String {
            didSet {
                preferredContentSize.width = CGFloat(message.count * 10)
            }
        }

        init(message: String) {
            self.message = message
            super.init(nibName: nil, bundle: nil)
            preferredContentSize.width = CGFloat(message.count * 10)
        }

        @available(*, unavailable) required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

#endif
