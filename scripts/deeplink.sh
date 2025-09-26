#!/bin/bash

# Verifica que se haya pasado un parámetro
if [ -z "$1" ]; then
  echo "Uso: $0 <deeplink>"
  exit 1
fi

DEEPLINK=$1

# Ejecuta el deeplink en el simulador booted
xcrun simctl openurl booted "$DEEPLINK"
