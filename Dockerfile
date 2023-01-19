# Build the Go Binary.
FROM golang:1.19 as service
ENV CGO_ENABLED 0
ARG BUILD_REF

# Create the service directory and the copy the module files first and then
# download the dependencies. If this doesn't change, we won't need to do this
# again in future builds.
# RUN mkdir /service
# COPY go.* /service/
# WORKDIR /service
# RUN go mod download

# Copy the source code into the container.
COPY . /service

# Build the service binary.
WORKDIR /service/app/services/service
RUN go build -ldflags "-X main.build=${BUILD_REF}"


# Run the Go Binary in Alpine.
FROM alpine:3.17
ARG BUILD_DATE
ARG BUILD_REF
RUN addgroup -g 1000 -S service && \
    adduser -u 1000 -h /service -G service -S service
COPY --from=service --chown=service:service /service/app/services/service/service /service
WORKDIR /service
USER service
CMD ["./service"]
