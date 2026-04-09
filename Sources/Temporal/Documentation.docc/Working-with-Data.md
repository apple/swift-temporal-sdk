# Configuring data conversion

Configure data conversion, serialization, and type-safe payload handling for
workflows and activities.

## Overview

Temporal applications serialize and deserialize data when passing
information between workflows and activities. The Swift Temporal SDK provides a
flexible data conversion system that handles serialization automatically while
allowing customization for specific requirements.

This article explains how the default data converter works and shows you how
to customize serialization with payload codecs, payload converters, and failure
converters.

## Use the default data converter

Data converters (``DataConverter``) combine a ``PayloadConverter``, an optional
``PayloadCodec``, and a ``FailureConverter``. Payload converters convert Swift
types to and from serialized bytes. Payload codecs transform bytes to bytes,
for example, by compressing or encrypting them. Failure converters convert
`Error` values to and from serialized failures.

The SDK provides ``DataConverter/default``, which uses the
``DefaultPayloadConverter`` that supports the following types:

- `nil`
- `Array<UInt8>` and `Data`
- `SwiftProtobuf.Message` by encoding to JSON
- `Codable`

The default payload converter is a ``CompositePayloadConverter`` — a collection
of types that conform to ``EncodingPayloadConverter``. The system tries each
converter in order until one successfully encodes a value. Each encoding
converter sets an `encoding` metadata value on the payload, which the system
uses to select the correct converter when deserializing bytes back into Swift
values.

For most applications, the default converter handles serialization without any
additional configuration.

## Add a custom payload codec

Implement a custom ``PayloadCodec`` when you need to transform serialized
payloads before they leave the worker — for example, to encrypt or compress
data. Payload codecs operate on already-serialized bytes, so they run after
the payload converter on encode and before the payload converter on decode.

A ``PayloadCodec`` requires two methods:
`encode(payloads:)` and `decode(payloads:)`. The following example encodes
payload data as Base64:

@Snippet(path: "swift-temporal-sdk/Snippets/DataConversion", slice: "base64PayloadCodec")

To use a custom codec, create a ``DataConverter`` that includes your codec and pass
the converter to your worker configuration:

@Snippet(path: "swift-temporal-sdk/Snippets/DataConversion", slice: "workerWithCodec")

> Important: Both the worker and any clients that read workflow data must use
> the same codec. If one side encodes with a codec and the other side doesn't
> decode with it, deserialization fails.

## Customize the payload converter

Implement a custom ``PayloadConverter`` when you need to change how Swift types
serialize to bytes — for example, to use a binary format instead of JSON.
Unlike payload codecs, payload converters **must be deterministic** because
they run inside workflows during replay.

Use ``CompositePayloadConverter`` to chain multiple ``EncodingPayloadConverter``
implementations together. The composite converter tries each converter in order until
it successfully encodes the value:

@Snippet(path: "swift-temporal-sdk/Snippets/DataConversion", slice: "compositePayloadConverter")

This mirrors how ``DefaultPayloadConverter`` works internally. Reorder or
replace individual converters to change serialization priority.

## Customize the failure converter

Implement a custom ``FailureConverter`` when you need to change how Swift errors
serialize to Temporal failure protos — for example, to include additional
diagnostic information or to strip sensitive details from error messages before
they reach the server.

The ``DefaultFailureConverter`` handles most use cases. It supports an
`encodeCommonAttributes` option that, when enabled, encodes the failure message
and stack trace into a binary payload rather than sending them as plaintext.
This provides a basic level of obfuscation for error details without requiring
a fully custom converter.
