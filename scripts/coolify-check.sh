#!/usr/bin/env bash
# Check que los composes que Coolify va a desplegar en este repositorio
# cumplen el contrato del plan (puntos 1 y 2) y, para bd: supabase-pg,
# dejan visibles DB_NAME=mvp_prueba y DB_SSLMODE=disable en el render.
#
# - Genera un .env temporal con valores no secretos (x123...) para cada
#   ${VAR} del compose (hosts/URLs usan ejemplo.invalid).
# - Para bd: supabase-pg agrega DB_SSLMODE=disable y DB_NAME=mvp_prueba.
# - Renderiza con `docker compose config --format json` y falla con
#   'servicio: motivo' por cada incumplimiento.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
note() { printf '%s\n' "$*"; }

# Compos que Coolify va a desplegar (relativos a REPO_ROOT).
# compose.bootstrap.yaml queda fuera: es sólo para desarrollo local y
# publica 127.0.0.1:8094 a propósito.
COMPOSES=(compose.yaml)

# Variables extra que el plan exige para aplicaciones bd: supabase-pg.
EXTRA_ENV=(
  'DB_SSLMODE=disable'
  'DB_NAME=mvp_prueba'
)

# Variables que parecen URL o host: les ponemos ejemplo.invalid.
URL_VAR_RE='(URL|ENDPOINT)$'
HOST_VAR_RE='_(HOST|HOSTNAME)$'

extract_vars() {
    grep -oE '\$\{?[A-Z_][A-Z0-9_]*\}?' "$REPO_ROOT/$1" \
        | sed -E 's/^\$\{?//; s/\}?$//' \
        | sort -u
}

build_env() {
    local compose="$1" env_file="$2"
    : >"$env_file"
    local v
    while read -r v; do
        [ -n "$v" ] || continue
        if [[ "$v" =~ $URL_VAR_RE ]]; then
            echo "$v='https://ejemplo.invalid'" >>"$env_file"
        elif [[ "$v" =~ $HOST_VAR_RE ]]; then
            echo "$v='ejemplo.invalid'" >>"$env_file"
        else
            echo "$v='x1234567890abcdef'" >>"$env_file"
        fi
    done < <(extract_vars "$compose")
    for kv in "${EXTRA_ENV[@]}"; do
        echo "$kv" >>"$env_file"
    done
}

render() {
    docker compose --project-directory "$REPO_ROOT" \
        -f "$REPO_ROOT/$1" \
        --env-file "$2" \
        config --format json
}

# Emite una línea por violación del contrato de un compose, tras renderizar.
# Las rutas absolutas que caen dentro de REPO_ROOT son válidas (Docker las
# resuelve desde el project dir); sólo se marcan docker.sock o rutas fuera
# usando boundary check (path boundary '/' o igualdad exacta) para evitar
# falsos negativos por prefijos.
contract_violations() {
    jq -r --arg repo "$REPO_ROOT" '
        def bad_src($s):
            ($s | type == "string") and
            (   ($s | test("docker\\.sock"))
              or (
                   ($s | startswith("/"))
                   and (($s == $repo) or ($s | startswith($repo + "/")) | not)
                 )
            );

        def mk($name; $msg):
            $name + ": " + $msg;

        [
            (
                (.services // {}) as $svcs
                | $svcs | to_entries[]
                | select(((.value.profiles // []) | length) == 0) as $s
                | $s.key as $name | $s.value as $svc
                | (
                    (($svc.ports // null)         != null) | if . then mk($name; "expone puertos") else empty end,
                    (($svc.container_name // null)!= null) | if . then mk($name; "container_name fijo (" + ($svc.container_name | tostring) + ")") else empty end,
                    (($svc.privileged // null)    != null) | if . then mk($name; "privileged") else empty end,
                    ((($svc.cap_add // [])        | length) > 0) | if . then mk($name; "cap_add (" + ($svc.cap_add | tostring) + ")") else empty end,
                    ((($svc.devices // [])        | length) > 0) | if . then mk($name; "devices (" + ($svc.devices | tostring) + ")") else empty end,
                    (($svc.network_mode // null)  != null) | if . then mk($name; "network_mode (" + ($svc.network_mode | tostring) + ")") else empty end,
                    ((($svc.pid // null) == "host"))          | if . then mk($name; "pid host") else empty end,
                    ((($svc.ipc // null) == "host"))          | if . then mk($name; "ipc host") else empty end,
                    ((($svc.security_opt // null) != null) and (($svc.security_opt | tostring) | test("unconfined"))) | if . then mk($name; "security_opt unconfined") else empty end,
                    (
                        (($svc.volumes // []) | map(
                            (. as $v |
                              (($v | type == "string") and bad_src($v))
                              or (($v | type == "object") and bad_src(($v.source // "" | tostring)))
                            )
                        ) | any)
                    ) | if . then mk($name; "bind fuera del repo o docker.sock") else empty end
                )
            )
        ] | .[]
    '
}

# Detecta en el FUENTE de un compose líneas `name:` con un valor literal
# (no derivado de ${VAR...}). Un `name: ${...}` se considera válido aunque
# tenga default; el contrato exige que cualquier nombre venga de una variable.
fixed_name_violations() {
    local compose="$1"
    # Coincide con líneas que tengan `name:` y el siguiente token NO empiece con `$`.
    # No opera contra renders para no perder el origen variable vs literal.
    grep -nE '^[[:space:]]*name:[[:space:]]+[^$[:space:]#]' "$REPO_ROOT/$compose" \
        | sed "s|^|$compose: |" \
        || true
}

# Llama a contract_violations sin silenciar el código de salida de jq.
# Devuelve el código 0 si jq devolvió violaciones (sólo stdout); 1 si jq
# falló (falla-abierta detectada) o hubo violaciones.
run_contract_check() {
    local rendered="$1" compose="$2"
    local vio
    if vio="$(printf '%s' "$rendered" | contract_violations)"; then
        if [ -n "$vio" ]; then
            printf '%s\n' "$vio"
            return 1
        fi
        return 0
    else
        echo "$compose: contract_violations falló (jq exit $?)" >&2
        return 1
    fi
}

overall_status=0
for compose in "${COMPOSES[@]}"; do
    note "== Comprobando $compose =="
    env_file="$TMP_DIR/${compose//\//_}.env"
    build_env "$compose" "$env_file"
    rendered="$(render "$compose" "$env_file")"

    if ! run_contract_check "$rendered" "$compose"; then
        overall_status=1
    fi

    # Nombres con valor literal (no derivado de ${VAR...}) en el FUENTE.
    fixed_vio="$(fixed_name_violations "$compose")"
    if [ -n "$fixed_vio" ]; then
        printf '%s\n' "$fixed_vio"
        overall_status=1
    fi

    # Para bd: supabase-pg el plan exige ver mvp_prueba y disable en el render.
    if ! grep -q -F 'mvp_prueba' <<<"$rendered"; then
        echo "$compose: mvp_prueba (DB_NAME) no aparece en el render"
        overall_status=1
    fi
    if ! grep -q -F 'disable' <<<"$rendered"; then
        echo "$compose: disable (DB_SSLMODE) no aparece en el render"
        overall_status=1
    fi
done

if [ "$overall_status" -ne 0 ]; then
    fail "composes no cumplen el contrato Coolify"
fi
note "OK: composes cumplen el contrato Coolify."
