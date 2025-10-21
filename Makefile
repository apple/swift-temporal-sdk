PROTO_OUT := ./Sources/Temporal/protos
PROTO_BASE := ./dependencies/sdk-core/sdk-core-protos/protos
PROTO_FILES := $(shell find $(PROTO_BASE) -name "*.proto" -not -path "*/google/*" -not -path "*/health/*")

SWIFT_CONFIGURATION ?= debug
SWIFT_BIN_PATH := $(shell swift build -c $(SWIFT_CONFIGURATION) --show-bin-path)

PROTOC_GEN_SWIFT := $(shell swift build -c release --show-bin-path)/protoc-gen-swift
PROTOC_GEN_GRPC_SWIFT := $(shell swift build -c release --show-bin-path)/protoc-gen-grpc-swift-2

# Build swift protobuf generation tool using swift build for use in other steps
$(PROTOC_GEN_SWIFT): Package.swift
	swift build -c release --product protoc-gen-swift
	swift build -c release --product protoc-gen-grpc-swift-2

.PHONY: build-protos
build-protos: $(PROTOC_GEN_SWIFT) $(PROTOC_GEN_GRPC_SWIFT) ./dependencies/sdk-core/sdk-core-protos/protos
	rm -rf $(PROTO_OUT)
	mkdir -p $(PROTO_OUT)
	protoc --plugin $(PROTOC_GEN_SWIFT) \
		--swift_out $(PROTO_OUT) \
		--swift_opt=FileNaming=PathToUnderscores \
		--swift_opt=Visibility=Package \
		--swift_opt=UseAccessLevelOnImports=true \
		-I ./dependencies/sdk-core/sdk-core-protos/protos/api_cloud_upstream \
		-I ./dependencies/sdk-core/sdk-core-protos/protos/api_upstream \
		-I ./dependencies/sdk-core/sdk-core-protos/protos/google \
        -I ./dependencies/sdk-core/sdk-core-protos/protos/grpc \
		-I ./dependencies/sdk-core/sdk-core-protos/protos/local \
        -I ./dependencies/sdk-core/sdk-core-protos/protos/testsrv_upstream \
		${PROTO_FILES}
	protoc --plugin $(PROTOC_GEN_GRPC_SWIFT) \
		--grpc-swift-2_out $(PROTO_OUT) \
		--grpc-swift-2_opt=FileNaming=PathToUnderscores \
		--grpc-swift-2_opt=Visibility=Package \
		--grpc-swift-2_opt=UseAccessLevelOnImports=true \
		--grpc-swift-2_opt=Client=true \
		--grpc-swift-2_opt=Server=false \
		-I ./dependencies/sdk-core/sdk-core-protos/protos/api_cloud_upstream \
		-I ./dependencies/sdk-core/sdk-core-protos/protos/api_upstream \
		-I ./dependencies/sdk-core/sdk-core-protos/protos/google \
		-I ./dependencies/sdk-core/sdk-core-protos/protos/grpc \
		-I ./dependencies/sdk-core/sdk-core-protos/protos/local \
		-I ./dependencies/sdk-core/sdk-core-protos/protos/testsrv_upstream \
		${PROTO_FILES}
