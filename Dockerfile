FROM golang:1.9-alpine as golang-build
RUN apk update && apk add --no-cache git
# Ideally we'd use a specific version of Glide.
RUN go get -u github.com/Masterminds/glide

ENV GOPATH /go

WORKDIR "${GOPATH}/src/github.com/alahijani/kuberos"
# Create the vendor directory based on glide.lock
ADD glide.yaml .
ADD glide.lock .
RUN glide install
# Build the binary
ADD . .
RUN go build -o "/dist/kuberos" ./cmd/kuberos


FROM node:carbon as nodejs-build
WORKDIR /frontend

ADD frontend/package.json .
RUN npm install

ADD frontend .
RUN npm run build


FROM alpine:3.5
RUN apk update && apk add --no-cache ca-certificates

WORKDIR /kuberos
COPY --from=golang-build /dist/kuberos .
COPY --from=nodejs-build /frontend/dist  ./frontend/dist/
COPY --from=nodejs-build /frontend/index.html ./frontend/

CMD /kuberos/kuberos
