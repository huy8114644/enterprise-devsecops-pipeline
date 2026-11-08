# Multi-stage Build for Maximum Security & Zero Vulnerabilities
# Stage 1: Build binary using official Go compiler
FROM golang:1.22-alpine AS builder

WORKDIR /src

# Install build dependencies & security certificates
RUN apk add --no-cache ca-certificates git

COPY go.mod ./
RUN go mod download

COPY . .

# Build static binary with CGO disabled & stripped symbols
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build     -ldflags="-w -s -extldflags '-static'"     -o /bin/order-api .

# Stage 2: Minimal Distroless Runtime (Non-root, zero shell, immutable)
FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /app

# Copy binary from builder
COPY --from=builder /bin/order-api /app/order-api

# Run as nonroot user (UID 65532)
USER 65532:65532

EXPOSE 8080

ENTRYPOINT ["/app/order-api"]

