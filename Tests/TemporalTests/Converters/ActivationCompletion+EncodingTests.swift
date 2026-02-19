//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftProtobuf
import Temporal
import Testing

@Suite
struct ActivationCompletionEncodingTests {
    @Test
    func encodeFailed() async throws {
        let payloadCodec = Base64PayloadCodec()
        let failure = Api.Failure.V1.Failure.with {
            $0.encodedAttributes = .with {
                $0.data = Data([1, 2, 3])
            }
        }
        var completion = Coresdk.WorkflowCompletion.WorkflowActivationCompletion.with {
            $0.failed = .with {
                $0.failure = failure
            }
        }

        try await completion.encode(payloadCodec: payloadCodec)

        let expectedFailure = Api.Failure.V1.Failure.with {
            $0.encodedAttributes = .with {
                $0.data = Data([1, 2, 3]).base64EncodedData()
                $0.metadata["codec"] = Data("application/base64".utf8)
            }
        }

        #expect(
            completion
                == .with {
                    $0.failed = .with {
                        $0.failure = expectedFailure
                    }
                }
        )
    }

    @Test
    func encodeSuccess() async throws {
        let payloadCodec = Base64PayloadCodec()
        let payload = Api.Common.V1.Payload.with {
            $0.data = Data([1, 2, 3])
        }
        let failure = Api.Failure.V1.Failure.with {
            $0.encodedAttributes = .with {
                $0.data = Data([1, 2, 3])
            }
        }
        var completion = Coresdk.WorkflowCompletion.WorkflowActivationCompletion.with {
            $0.successful = .with {
                $0.commands = [
                    .with {
                        $0.variant = .scheduleActivity(
                            .with {
                                $0.arguments = [payload, payload]
                                $0.headers = ["header1": payload, "header2": payload]
                            }
                        )
                    },
                    .with {
                        $0.variant = .respondToQuery(
                            .with {
                                $0.succeeded = .with {
                                    $0.response = payload
                                }
                            }
                        )
                    },
                    .with {
                        $0.variant = .respondToQuery(
                            .with {
                                $0.failed = failure
                            }
                        )
                    },
                    .with {
                        $0.variant = .completeWorkflowExecution(
                            .with {
                                $0.result = payload
                            }
                        )
                    },
                    .with {
                        $0.variant = .failWorkflowExecution(
                            .with {
                                $0.failure = failure
                            }
                        )
                    },
                    .with {
                        $0.variant = .continueAsNewWorkflowExecution(
                            .with {
                                $0.arguments = [payload, payload]
                                $0.memo = ["memo": payload]
                                $0.headers = ["header1": payload, "header2": payload]
                                $0.searchAttributes = ["search": payload]
                            }
                        )
                    },
                    .with {
                        $0.variant = .startChildWorkflowExecution(
                            .with {
                                $0.input = [payload, payload]
                                $0.memo = ["memo": payload]
                                $0.headers = ["header1": payload, "header2": payload]
                                $0.searchAttributes = ["search": payload]
                            }
                        )
                    },
                    .with {
                        $0.variant = .signalExternalWorkflowExecution(
                            .with {
                                $0.args = [payload, payload]
                                $0.headers = ["header1": payload, "header2": payload]
                            }
                        )
                    },
                    .with {
                        $0.variant = .scheduleLocalActivity(
                            .with {
                                $0.arguments = [payload, payload]
                                $0.headers = ["header1": payload, "header2": payload]
                            }
                        )
                    },
                    .with {
                        $0.variant = .upsertWorkflowSearchAttributes(
                            .with {
                                $0.searchAttributes = ["search": payload]
                            }
                        )
                    },
                    .with {
                        $0.variant = .modifyWorkflowProperties(
                            .with {
                                $0.upsertedMemo = .with {
                                    $0.fields = ["memo": payload]
                                }
                            }
                        )
                    },
                    .with {
                        $0.variant = .updateResponse(
                            .with {
                                $0.completed = payload
                            }
                        )
                    },
                    .with {
                        $0.variant = .updateResponse(
                            .with {
                                $0.rejected = failure
                            }
                        )
                    },
                    .with {
                        $0.variant = .scheduleNexusOperation(
                            .with {
                                $0.input = payload
                            }
                        )
                    },
                ]
            }
        }

        try await completion.encode(payloadCodec: payloadCodec)

        let expectedPayload = Api.Common.V1.Payload.with {
            $0.data = Data([1, 2, 3]).base64EncodedData()
            $0.metadata["codec"] = Data("application/base64".utf8)
        }
        let expectedFailure = Api.Failure.V1.Failure.with {
            $0.encodedAttributes = .with {
                $0.data = Data([1, 2, 3]).base64EncodedData()
                $0.metadata["codec"] = Data("application/base64".utf8)
            }
        }

        #expect(
            completion
                == .with {
                    $0.successful = .with {
                        $0.commands = [
                            .with {
                                $0.variant = .scheduleActivity(
                                    .with {
                                        $0.arguments = [expectedPayload, expectedPayload]
                                        $0.headers = ["header1": expectedPayload, "header2": expectedPayload]
                                    }
                                )
                            },
                            .with {
                                $0.variant = .respondToQuery(
                                    .with {
                                        $0.succeeded = .with {
                                            $0.response = expectedPayload
                                        }
                                    }
                                )
                            },
                            .with {
                                $0.variant = .respondToQuery(
                                    .with {
                                        $0.failed = expectedFailure
                                    }
                                )
                            },
                            .with {
                                $0.variant = .completeWorkflowExecution(
                                    .with {
                                        $0.result = expectedPayload
                                    }
                                )
                            },
                            .with {
                                $0.variant = .failWorkflowExecution(
                                    .with {
                                        $0.failure = expectedFailure
                                    }
                                )
                            },
                            .with {
                                $0.variant = .continueAsNewWorkflowExecution(
                                    .with {
                                        $0.arguments = [expectedPayload, expectedPayload]
                                        $0.memo = ["memo": expectedPayload]
                                        $0.headers = ["header1": expectedPayload, "header2": expectedPayload]
                                        $0.searchAttributes = ["search": expectedPayload]
                                    }
                                )
                            },
                            .with {
                                $0.variant = .startChildWorkflowExecution(
                                    .with {
                                        $0.input = [expectedPayload, expectedPayload]
                                        $0.memo = ["memo": expectedPayload]
                                        $0.headers = ["header1": expectedPayload, "header2": expectedPayload]
                                        $0.searchAttributes = ["search": expectedPayload]
                                    }
                                )
                            },
                            .with {
                                $0.variant = .signalExternalWorkflowExecution(
                                    .with {
                                        $0.args = [expectedPayload, expectedPayload]
                                        $0.headers = ["header1": expectedPayload, "header2": expectedPayload]
                                    }
                                )
                            },
                            .with {
                                $0.variant = .scheduleLocalActivity(
                                    .with {
                                        $0.arguments = [expectedPayload, expectedPayload]
                                        $0.headers = ["header1": expectedPayload, "header2": expectedPayload]
                                    }
                                )
                            },
                            .with {
                                $0.variant = .upsertWorkflowSearchAttributes(
                                    .with {
                                        $0.searchAttributes = ["search": expectedPayload]
                                    }
                                )
                            },
                            .with {
                                $0.variant = .modifyWorkflowProperties(
                                    .with {
                                        $0.upsertedMemo = .with {
                                            $0.fields = ["memo": expectedPayload]
                                        }
                                    }
                                )
                            },
                            .with {
                                $0.variant = .updateResponse(
                                    .with {
                                        $0.completed = expectedPayload
                                    }
                                )
                            },
                            .with {
                                $0.variant = .updateResponse(
                                    .with {
                                        $0.rejected = expectedFailure
                                    }
                                )
                            },
                            .with {
                                $0.variant = .scheduleNexusOperation(
                                    .with {
                                        $0.input = expectedPayload
                                    }
                                )
                            },
                        ]
                    }
                }
        )
    }
}
