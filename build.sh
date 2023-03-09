#!/bin/bash

SCRIPT_DIR="`dirname -- "$0"`"
GEN_DIR="$SCRIPT_DIR/gen"
PROTO_DIR="$SCRIPT_DIR/opentelemetry/proto"
CLASSES_DIR="$SCRIPT_DIR/classes"
JAR_FILE="$SCRIPT_DIR/opentelemetry-proto.jar"
OUT_DIR="$SCRIPT_DIR/../../lib"

echo "Ensuring that protoc is installed." 
protoc --version
if [ $? -ne 0 ]; then
    echo "Error: Could not find protoc binary." >&2  
    echo "Hint: \`sudo apt install protobuf-compiler\`" >&2
    exit 1
fi

echo "Checking for Java gRPC protoc plugin."
if [ ! -f "$SCRIPT_DIR/protoc-gen-grpc-java" ]; then
    echo "Error: Missing Java gRPC protoc plugin." >&2
    echo "Hint: Check https://github.com/grpc/grpc-java/tree/master/compiler for instructions. You probably need to download the latest version of the plugin, put it in the root directory, and rename it to \"protoc-gen-grpc-java\"." >&2
    exit 1
fi

if [ -e "$GEN_DIR" ]; then
    rm -rf "$GEN_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Unable to delete existing $GEN_DIR dir." >&2 
        exit 1
    fi
fi
mkdir "$GEN_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Unable to create $GEN_DIR dir." >&2
    exit 1
fi

if [ ! -e "$PROTO_DIR" ]; then
    echo "Error: Missing $PROTO_DIR dir." >&2
    exit 1
fi

echo "Generating Java source files to $GEN_DIR dir."
find "$PROTO_DIR" -name "*.proto" | while read file; do
    protoc --proto_path="." --java_out="$GEN_DIR" --grpc-java_out="$GEN_DIR" --plugin="protoc-gen-grpc-java=$SCRIPT_DIR/protoc-gen-grpc-java" --experimental_allow_proto3_optional "$file"
done

echo "Compiling Java source files to $CLASSES_DIR dir."
if [ -e "$CLASSES_DIR" ]; then
    rm -rf "$CLASSES_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Unable to delete existing $CLASSES_DIR dir." >&2 
        exit 1
    fi
fi
mkdir "$CLASSES_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Unable to create $CLASSES_DIR dir." >&2
    exit 1
fi
javac -d "$CLASSES_DIR" -cp "../ivylib/*" $(find "$GEN_DIR" -name "*.java")

echo "Creating $JAR_FILE file."
jar -cvf "$JAR_FILE" -C "$CLASSES_DIR" .
if [ ! -f "$JAR_FILE" ]; then
    echo "Error: Unable to create $JAR_FILE file." >&2
    exit 1
fi

echo "Copying $JAR_FILE into $OUT_DIR dir."
cp "$JAR_FILE" "$OUT_DIR"

echo "Done. Output written to $OUT_DIR/opentelemetry-proto.jar"

