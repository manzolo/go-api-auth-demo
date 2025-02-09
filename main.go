package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"
	"os"

	"github.com/golang-jwt/jwt/v4"
)

// Response struttura della risposta in formato JSON
type Response struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

// Chiave segreta per la firma dei JWT
var jwtSecret = []byte(os.Getenv("MY_JWT_SECRET"))

// Handler per l'endpoint pubblico
func publicHandler(w http.ResponseWriter, r *http.Request) {
	response := Response{Code: 200, Message: "Accesso consentito: endpoint pubblico."}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Carichiamo le credenziali dal secret (che devono essere impostate nelle ENV)
var basicAuthUsername = os.Getenv("BASIC_AUTH_USERNAME")
var basicAuthPassword = os.Getenv("BASIC_AUTH_PASSWORD")

// Handler per Basic Authentication
func basicAuthHandler(w http.ResponseWriter, r *http.Request) {
	username, password, ok := r.BasicAuth()
	if !ok || username != basicAuthUsername || password != basicAuthPassword {
		w.Header().Set("WWW-Authenticate", `Basic realm="Area Riservata"`)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(Response{Code: 401, Message: "Autenticazione fallita"})
		return
	}
	json.NewEncoder(w).Encode(Response{Code: 200, Message: "Autenticazione avvenuta con successo."})
}

var myToken = os.Getenv("MY_TOKEN")
// Handler per Token Authentication (token statico)
func tokenAuthHandler(w http.ResponseWriter, r *http.Request) {
	authHeader := r.Header.Get("Authorization")
	if authHeader != "Bearer " + myToken {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(Response{Code: 401, Message: "Autenticazione tramite token fallita"})
		return
	}
	response := Response{Code: 200, Message: "Token Auth: autenticazione avvenuta con successo."}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Handler per JWT Authentication
func jwtAuthHandler(w http.ResponseWriter, r *http.Request) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(Response{Code: 401, Message: "JWT token non fornito o malformato"})
		return
	}
	tokenString := strings.TrimPrefix(authHeader, "Bearer ")

	// Parsing e validazione del token JWT
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		// Controlla il metodo di firma
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("metodo di firma inatteso: %v", token.Header["alg"])
		}
		return jwtSecret, nil
	})
	if err != nil || !token.Valid {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(Response{Code: 401, Message: "JWT token non valido"})
		return
	}

	response := Response{Code: 200, Message: "JWT Auth: autenticazione avvenuta con successo."}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

var MyApiKey = os.Getenv("MY_API_KEY")

// Handler per API Key Authentication
func apiKeyAuthHandler(w http.ResponseWriter, r *http.Request) {
	apiKey := r.Header.Get("X-API-Key")
	if apiKey != MyApiKey {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(Response{Code: 401, Message: "API Key non valida o non fornita"})
		return
	}
	response := Response{Code: 200, Message: "API Key Auth: autenticazione avvenuta con successo."}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// (Opzionale) Handler per generare un token JWT di esempio
func generateJWTHandler(w http.ResponseWriter, r *http.Request) {
	// Crea un token con validità di 1 ora
	claims := jwt.MapClaims{
		"username": "DemoUser",
		"exp":      time.Now().Add(time.Hour * 1).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(jwtSecret)
	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(Response{Code: 500, Message: "Errore nella generazione del token"})
		return
	}

	response := Response{Code: 200, Message: tokenString}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func main() {
	// Registrazione degli endpoint
	http.HandleFunc("/public", publicHandler)
	http.HandleFunc("/basic", basicAuthHandler)
	http.HandleFunc("/token", tokenAuthHandler)
	http.HandleFunc("/apikey", apiKeyAuthHandler)
	// Endpoint opzionale per generare un JWT (utile per test)
	http.HandleFunc("/generate-jwt", generateJWTHandler)
	http.HandleFunc("/jwt", jwtAuthHandler)

	log.Println("Server in ascolto sulla porta 8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
