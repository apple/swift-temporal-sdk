//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftProtobuf
import Temporal
import Testing

@Suite
struct ActivationDecodingTests {
    @Test
    func decode() async throws {
        let payloadCodec = Base64PayloadCodec()
        let payload = Temporal_Api_Common_V1_Payload.with {
            $0.data = Data([1, 2, 3]).base64EncodedData()
            $0.metadata["codec"] = Data("application/base64".utf8)
        }
        let failure = Temporal_Api_Failure_V1_Failure.with {
            $0.encodedAttributes = .with {
                $0.data = Data([1, 2, 3]).base64EncodedData()
                $0.metadata["codec"] = Data("application/base64".utf8)
            }
        }
        var activation = Coresdk_WorkflowActivation_WorkflowActivation.with {
            $0.jobs = [
                .with {
                    $0.variant = .initializeWorkflow(
                        .with {
                            $0.arguments = [payload]
                            $0.headers = ["header": payload]
                            $0.continuedFailure = failure
                            $0.lastCompletionResult = .with { $0.payloads = [payload] }
                            $0.memo = .with { $0.fields = ["memo": payload] }
                            $0.searchAttributes = .with { $0.indexedFields = ["attribute": payload] }
                        }
                    )
                },
                .with {
                    $0.variant = .queryWorkflow(
                        .with {
                            $0.arguments = [payload]
                            $0.headers = ["header": payload]
                        }
                    )
                },
                .with {
                    $0.variant = .signalWorkflow(
                        .with {
                            $0.input = [payload]
                            $0.headers = ["header": payload]
                        }
                    )
                },
                .with {
                    $0.variant = .resolveActivity(
                        .with {
                            $0.result.completed = .with { $0.result = payload }
                        }
                    )
                },
                .with {
                    $0.variant = .resolveActivity(
                        .with {
                            $0.result.cancelled = .with { $0.failure = failure }
                        }
                    )
                },
                .with {
                    $0.variant = .resolveActivity(
                        .with {
                            $0.result.failed = .with { $0.failure = failure }
                        }
                    )
                },
                .with {
                    $0.variant = .resolveChildWorkflowExecutionStart(
                        .with {
                            $0.cancelled = .with { $0.failure = failure }
                        }
                    )
                },
                .with {
                    $0.variant = .resolveChildWorkflowExecution(
                        .with {
                            $0.result.completed = .with { $0.result = payload }
                        }
                    )
                },
                .with {
                    $0.variant = .resolveChildWorkflowExecution(
                        .with {
                            $0.result.failed = .with { $0.failure = failure }
                        }
                    )
                },
                .with {
                    $0.variant = .resolveChildWorkflowExecution(
                        .with {
                            $0.result.cancelled = .with { $0.failure = failure }
                        }
                    )
                },
                .with {
                    $0.variant = .resolveSignalExternalWorkflow(
                        .with {
                            $0.failure = failure
                        }
                    )
                },
                .with {
                    $0.variant = .resolveRequestCancelExternalWorkflow(
                        .with {
                            $0.failure = failure
                        }
                    )
                },
                .with {
                    $0.variant = .doUpdate(
                        .with {
                            $0.input = [payload]
                            $0.headers = ["header": payload]
                        }
                    )
                },
                .with {
                    $0.variant = .resolveNexusOperationStart(
                        .with {
                            $0.failed = failure
                        }
                    )
                },
                .with {
                    $0.variant = .resolveNexusOperation(
                        .with {
                            $0.result.completed = payload
                        }
                    )
                },
                .with {
                    $0.variant = .resolveNexusOperation(
                        .with {
                            $0.result.failed = failure
                        }
                    )
                },
                .with {
                    $0.variant = .resolveNexusOperation(
                        .with {
                            $0.result.cancelled = failure
                        }
                    )
                },
                .with {
                    $0.variant = .resolveNexusOperation(
                        .with {
                            $0.result.timedOut = failure
                        }
                    )
                },
            ]
        }

        try await activation.decode(payloadCodec: payloadCodec)

        let expectedPayload = Temporal_Api_Common_V1_Payload.with {
            $0.data = Data([1, 2, 3])
        }
        let expectedFailure = Temporal_Api_Failure_V1_Failure.with {
            $0.encodedAttributes = .with {
                $0.data = Data([1, 2, 3])
            }
        }

        #expect(
            activation
                == .with {
                    $0.jobs = [
                        .with {
                            $0.variant = .initializeWorkflow(
                                .with {
                                    $0.arguments = [expectedPayload]
                                    $0.headers = ["header": expectedPayload]
                                    $0.continuedFailure = expectedFailure
                                    $0.lastCompletionResult = .with { $0.payloads = [expectedPayload] }
                                    $0.memo = .with { $0.fields = ["memo": expectedPayload] }
                                    $0.searchAttributes = .with { $0.indexedFields = ["attribute": expectedPayload] }
                                }
                            )
                        },
                        .with {
                            $0.variant = .queryWorkflow(
                                .with {
                                    $0.arguments = [expectedPayload]
                                    $0.headers = ["header": expectedPayload]
                                }
                            )
                        },
                        .with {
                            $0.variant = .signalWorkflow(
                                .with {
                                    $0.input = [expectedPayload]
                                    $0.headers = ["header": expectedPayload]
                                }
                            )
                        },
                        .with {
                            $0.variant = .resolveActivity(
                                .with {
                                    $0.result.completed = .with { $0.result = expectedPayload }
                                }
                            )
                        },
                        .with {
                            $0.variant = .resolveActivity(
                                .with {
                                    $0.result.cancelled = .with { $0.failure = expectedFailure }
                                }
                            )
                        },
                        .with {
                            $0.variant = .resolveActivity(
                                .with {
                                    $0.result.failed = .with { $0.failure = expectedFailure }
                                }
                            )
                        },
                        .with {
                            $0.variant = .resolveChildWorkflowExecutionStart(
                                .with {
                                    $0.cancelled = .with { $0.failure = expectedFailure }
                                }
                            )
                        },
                        .with {
                            $0.variant = .resolveChildWorkflowExecution(
                                .with {
                                    $0.result.completed = .with { $0.result = expectedPayload }
                                }
                            )
                        },
                        .with {
                            $0.variant = .resolveChildWorkflowExecution(
                                .with {
                                    $0.result.failed = .with { $0.failure = expectedFailure }
                                }
                            )
                        },
                        .with {
                            $0.variant = .resolveChildWorkflowExecution(
                                .with {
                                    $0.result.cancelled = .with { $0.failure = expectedFailure }
                                }
                            )
                        },
                        .with {
                            $0.variant = .resolveSignalExternalWorkflow(
                                .with {
                                    $0.failure = expectedFailure
                                }
                            )
                        },
                        .with {
                            $0.variant = .resolveRequestCancelExternalWorkflow(
                                .with {
                                    $0.failure = expectedFailure
                                }
                            )
                        },
                        .with {
                            $0.variant = .doUpdate(
                                .with {
                                    $0.input = [expectedPayload]
                                    $0.headers = ["header": expectedPayload]
                                }
                            )
                        },
                        .with {
                            $0.variant = .resolveNexusOperationStart(
                                .with {
                                    $0.failed = expectedFailure
                                }
                            )
                        },
                        .with {
                            $0.variant = .resolveNexusOperation(
                                .with {
                                    $0.result.completed = expectedPayload
                                }
                            )
                        },
                        .with {
                            $0.variant = .resolveNexusOperation(
                                .with {
                                    $0.result.failed = expectedFailure
                                }
                            )
                        },
                        .with {
                            $0.variant = .resolveNexusOperation(
                                .with {
                                    $0.result.cancelled = expectedFailure
                                }
                            )
                        },
                        .with {
                            $0.variant = .resolveNexusOperation(
                                .with {
                                    $0.result.timedOut = expectedFailure
                                }
                            )
                        },
                    ]
                }
        )
    }
}
