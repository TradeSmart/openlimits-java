# OpenLimits Java Wrapper

Starting point for Openlimits wrapper in Java using rust-jni for java-python bindings.

# Build and use package locally

Make sure you have rust installed on your system.

To build and update the jar paths run `./gradlew build -x test && ./build-jars.sh && ./update-jar-path.sh`

# Deploy build
```
aws cloudformation deploy \
    --template-file build.yaml \
    --stack-name il-openlimits-java \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region us-east-1 \
    --profile tuned-ss
```