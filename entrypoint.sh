#!/bin/sh
# Se il file del secret esiste, leggilo ed esporta la variabile d'ambiente
if [ -f /run/secrets/my_jwt_secret ]; then
  export MY_JWT_SECRET=$(cat /run/secrets/my_jwt_secret)
fi
if [ -f /run/secrets/basic_auth_username ]; then
  export BASIC_AUTH_USERNAME=$(cat /run/secrets/basic_auth_username)
fi
if [ -f /run/secrets/basic_auth_password ]; then
  export BASIC_AUTH_PASSWORD=$(cat /run/secrets/basic_auth_password)
fi
if [ -f /run/secrets/my_api_key ]; then
  export MY_API_KEY=$(cat /run/secrets/my_api_key)
fi
if [ -f /run/secrets/my_token ]; then
  export MY_TOKEN=$(cat /run/secrets/my_token)
fi
# Avvia il comando passato (ad es. l'app Go)
exec "$@"