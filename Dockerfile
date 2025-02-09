# Stage 1: Build dell'applicazione Go
FROM golang:1.23-alpine AS builder
WORKDIR /app
# Copia i file go.mod e go.sum e scarica le dipendenze
#COPY go.mod go.sum ./
#RUN go mod download
RUN go mod init go-api && go get github.com/golang-jwt/jwt/v4
# Copia il resto dei file sorgente
COPY main.go .
# Compila l'applicazione
RUN go build -o go-api .

# Stage 2: Immagine finale
FROM alpine:latest
WORKDIR /root/
# Copia l'eseguibile dall'immagine builder
COPY --from=builder /app/go-api .

# Aggiungo curl per health check
RUN apk add --no-cache curl

# Esponi la porta 8080
EXPOSE 8080

# Copia lo script entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Definisce l'entrypoint e il comando di default
ENTRYPOINT ["/entrypoint.sh"]

# Avvia l'applicazione
CMD ["./go-api"]
