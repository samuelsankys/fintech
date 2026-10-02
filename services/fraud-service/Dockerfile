FROM golang:1.22 AS build
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server .

FROM gcr.io/distroless/static-debian12
COPY --from=build /app/server /app/server
EXPOSE 8091
ENTRYPOINT ["/app/server"]
