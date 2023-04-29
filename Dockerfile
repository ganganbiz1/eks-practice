FROM golang:1.20-alpine as dev

ENV ROOT=/go/src/app
ENV CGO_ENABLED 0
WORKDIR ${ROOT}
RUN apk update && apk add git
COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

EXPOSE 8080

CMD ["go", "run", "main.go"]

FROM golang:1.20-alpine as builder

ENV ROOT=/go/src/app
WORKDIR ${ROOT}
# alpineは最低限しか入ってないので、アップデートとgitのインストールしておく
RUN apk update && apk add git
RUN addgroup apiuser
RUN adduser -G apiuser -D apiuser
COPY go.mod go.sum ./
RUN go mod download

COPY . ${ROOT}
RUN CGO_ENABLED=0 GOOS=linux go build -o $ROOT/binary

FROM scratch as prod
ENV ROOT=/go/src/app
WORKDIR ${ROOT}

COPY --from=builder ${ROOT}/binary ${ROOT}
COPY --from=builder /etc/passwd /etc/passwd

USER apiuser
EXPOSE 8080
CMD ["/go/src/app/binary"]