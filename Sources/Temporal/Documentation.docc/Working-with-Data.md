# Data conversion

Configure data conversion, serialization, and type-safe payload handling for
workflows and activities.

## Overview

Temporal applications serialize and deserialize data when passing
information between workflows and activities. The Swift Temporal SDK provides a
flexible data conversion system that handles serialization automatically while
allowing customization for specific requirements.

This article shows you how to work with the default data converters, implement
custom serialization logic, configure payload codecs for encryption or
compression, and handle complex data types safely in your Temporal
applications.

### Use the default data converter

Data converters (``DataConverter``) are a combination of ``PayloadConverter``, ``PayloadCodec`` and
``FailureConverter``. Payload converters convert Swift types to and from
serialized bytes. Payload codecs convert bytes to bytes, for example compressing
or encrypting them. Failure converters convert `Error`s to and from serialized
failures.

The SDK provides the ``DataConverter/default`` which uses the
``DefaultPayloadConverter`` that supports the following types:

- `nil`
- `Array<UInt8>` and `Data`
- `SwiftProtobuf.Message` by encoding to JSON
- `Codable`

The default payload converter is a collection of types that conform to ``EncodingPayloadConverter``.
Each converter is tried in order until one can successfully encode a value.
The encoding converters also set an `encoding` metadata value, which is used
to identify the correct converter to use when deserializing bytes into Swift values.

### Implement custom data converters

Create a custom data converter by providing a payload converter, payload codec,
or failure converter to the ``DataConverter/init(payloadConverter:failureConverter:payloadCodec:)``.

Use the ``CompositePayloadConverter`` to create payload converter chains
similar to how the default payload converter works.
