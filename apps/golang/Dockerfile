ARG GO_VERSION=1.20.1

FROM golang:${GO_VERSION} AS build
COPY src/ /app
WORKDIR /app
RUN CGO_ENABLED=0 go build -o /sample /app/*

FROM gcr.io/distroless/static:latest
USER nonroot:nonroot
WORKDIR /app
COPY --from=build --chown=nonroot:nonroot /sample /app/sample
EXPOSE 80
ENTRYPOINT ["/app/sample"]
