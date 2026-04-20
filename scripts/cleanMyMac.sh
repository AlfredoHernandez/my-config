#!/bin/bash

# Ensure the script is run as root
if [[ "$EUID" -ne 0 ]]; then
    echo "Por favor, ejecute el script como root usando sudo."
    exit 1
fi

# Espacio mínimo en disco en KB (50 GB en este caso)
MIN_SPACE=$((900 * 1024 * 1024))  # 50 GB convertido a KB

# Obtener el espacio libre en el disco en KB
FREE_SPACE=$(df -k / | tail -1 | awk '{print $4}')

if [[ "$FREE_SPACE" -lt "$MIN_SPACE" ]]; then
    echo "Espacio en disco insuficiente: $FREE_SPACE KB. Iniciando limpieza..."

    # Función para eliminar directorios de forma segura con comodines
    remove_path() {
        local path="$1"
        # Expandir los comodines
        shopt -s nullglob
        local files=($path)
        shopt -u nullglob
        if [[ ${#files[@]} -gt 0 ]]; then
            echo "Eliminando $path..."
            rm -rf $path
        else
            echo "El directorio $path no existe o ya ha sido eliminado."
        fi
    }

    # Rutas a limpiar
    SYSTEM_CACHE="/Library/Caches/*"
    USER_CACHE="$HOME/Library/Caches/*"
    TMP_DIRS=("/tmp/*" "/var/tmp/*")
    LOG_FILES="/var/log/*"
    TRASH="$HOME/.Trash/*"
    XCODE_PATHS=(
        "$HOME/Library/Developer/Xcode/DerivedData/*"
        "$HOME/Library/Developer/Xcode/Archives/*"
        "$HOME/Library/Developer/Xcode/iOS DeviceSupport/*"
    )

    # Limpiar la caché del sistema
    echo "Limpiando caché del sistema..."
    remove_path "$SYSTEM_CACHE"

    # Limpiar la caché del usuario
    echo "Limpiando caché del usuario..."
    remove_path "$USER_CACHE"

    # Eliminar archivos temporales
    echo "Eliminando archivos temporales..."
    for dir in "${TMP_DIRS[@]}"; do
        remove_path "$dir"
    done

    # Limpiar archivos de registros (logs)
    echo "Limpiando archivos de registros..."
    remove_path "$LOG_FILES"

    # Eliminar archivos de la papelera
    echo "Vaciando la papelera..."
    remove_path "$TRASH"

    # Eliminar archivos relacionados con Xcode
    echo "Eliminando archivos de Xcode..."
    for path in "${XCODE_PATHS[@]}"; do
        remove_path "$path"
    done

    echo "Limpieza completada."

else
    echo "Suficiente espacio en disco: $FREE_SPACE KB. No es necesario realizar limpieza."
fi

# Finalización
echo "Script terminado."