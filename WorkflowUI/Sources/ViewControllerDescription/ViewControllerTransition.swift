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

    public struct ViewControllerTransition {
        private var setup: (Context) -> Void
        private var animate: (Context) -> Void

        init(
            setup: @escaping (Context) -> Void,
            animate: @escaping (Context) -> Void
        ) {
            self.setup = setup
            self.animate = animate
        }

        func transition(
            from: UIView,
            to: UIView,
            in container: UIView,
            animated: Bool,
            setup: @escaping () -> Void,
            completion: @escaping () -> Void
        ) {
            let context = Context(from: from, to: to, in: container, completion: completion)

            if animated {
                UIView.performWithoutAnimation {
                    self.setup(context)
                    setup()
                }

                animate(context)
            } else {
                to.frame = container.bounds
                container.addSubview(to)
                from.removeFromSuperview()
                context.setCompleted()
            }
        }
    }

    public extension ViewControllerTransition {
        final class Context {
            public let from: UIView
            public let to: UIView
            public let container: UIView

            private var state: State

            enum State {
                case running(() -> Void)
                case complete
            }

            init(from: UIView, to: UIView, in container: UIView, completion: @escaping () -> Void) {
                self.from = from
                self.to = to
                self.container = container
                self.state = .running(completion)
            }

            public func setCompleted() {
                guard case .running(let completion) = state else {
                    fatalError()
                }

                state = .complete

                completion()
            }
        }
    }

    public extension ViewControllerTransition {
        static var none: Self {
            .init(
                setup: { context in
                    context.to.frame = context.container.bounds
                },
                animate: { context in
                    context.setCompleted()
                }
            )
        }

        static func fade(with duration: TimeInterval) -> Self {
            fatalError()
        }
    }

#endif
