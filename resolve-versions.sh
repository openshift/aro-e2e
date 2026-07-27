#!/bin/bash
#
# Resolve latest non-forbidden versions of aro-ansible dependencies.
# Designed to run inside a container (requires: bash, curl, jq).
#
# Modes:
#   resolve-versions.sh FORBIDDEN_FILE --build-args
#       Output --build-arg flags for podman/buildah build (on one line).
#
#   resolve-versions.sh FORBIDDEN_FILE --update DOCKERFILE REQUIREMENTS_FILE
#       Update pinned versions in the given files in place.

set -euo pipefail

forbidden_file="${1:?Usage: resolve-versions.sh FORBIDDEN_FILE (--build-args | --update DOCKERFILE REQUIREMENTS)}"
shift
mode="${1:---build-args}"
shift || true

# ---------------------------------------------------------------------------
# Forbidden versions
# ---------------------------------------------------------------------------
declare -A FORBIDDEN
if [[ -f "${forbidden_file}" ]]; then
    while IFS= read -r line; do
        line="${line%%#*}"
        line="$(echo "${line}" | xargs)"
        [[ -z "${line}" ]] && continue
        read -r pkg ver <<<"${line}"
        FORBIDDEN["${pkg} ${ver}"]=1
    done <"${forbidden_file}"
fi

is_forbidden() {
    [[ -n "${FORBIDDEN["${1} ${2}"]:-}" ]]
}

# ---------------------------------------------------------------------------
# PyPI
# ---------------------------------------------------------------------------
get_pypi_latest() {
    local package="${1}"
    local data
    data="$(curl -fsSL "https://pypi.org/pypi/${package}/json")"

    local latest
    latest="$(echo "${data}" | jq -r '.info.version')"
    if ! is_forbidden "${package}" "${latest}"; then
        echo "${latest}"
        return
    fi

    echo >&2 "${package}: ${latest} is forbidden, finding previous release"
    local selected
    selected="$(echo "${data}" | jq -r '
        [.releases | to_entries[]
         | select(.value | length > 0)
         | select(.value | all(.yanked | not))
         | {version: .key,
            ts: (.value | map(.upload_time_iso_8601) | sort | first)}]
        | sort_by(.ts)
        | reverse
        | .[].version' | while read -r ver; do
            if ! is_forbidden "${package}" "${ver}"; then
                echo "${ver}"
                break
            fi
        done)"

    if [[ -z "${selected}" ]]; then
        echo >&2 "${package}: no non-forbidden version found"
        return 1
    fi
    echo "${selected}"
}

# ---------------------------------------------------------------------------
# Ansible Galaxy
# ---------------------------------------------------------------------------
get_galaxy_latest() {
    local ns="${1}" name="${2}"
    local package="${ns}.${name}"
    local data
    data="$(curl -fsSL \
        "https://galaxy.ansible.com/api/v3/plugin/ansible/content/published/collections/index/${ns}/${name}/")"

    local latest
    latest="$(echo "${data}" | jq -r '.highest_version.version')"
    if ! is_forbidden "${package}" "${latest}"; then
        echo "${latest}"
        return
    fi

    echo >&2 "${package}: ${latest} is forbidden, finding previous release"
    local versions_url
    versions_url="$(echo "${data}" | jq -r '.versions_url')"
    local selected
    selected="$(curl -fsSL "https://galaxy.ansible.com${versions_url}" \
        | jq -r '.data[].version' | while read -r ver; do
            if ! is_forbidden "${package}" "${ver}"; then
                echo "${ver}"
                break
            fi
        done)"

    if [[ -z "${selected}" ]]; then
        echo >&2 "${package}: no non-forbidden version found"
        return 1
    fi
    echo "${selected}"
}

# ---------------------------------------------------------------------------
# Resolve all Dockerfile ARG specs
# ---------------------------------------------------------------------------
declare -A SPECS

echo >&2 "Resolving latest versions..."

declare -A PYPI_PACKAGES=(
    ["PIPX_SPEC"]="pipx"
    ["ANSIBLE_SPEC"]="ansible"
    ["AZURE_CLI_SPEC"]="azure-cli"
    ["ANSIBLE_LINT_SPEC"]="ansible-lint"
)

for arg in "${!PYPI_PACKAGES[@]}"; do
    pkg="${PYPI_PACKAGES[${arg}]}"
    ver="$(get_pypi_latest "${pkg}")"
    SPECS["${arg}"]="${pkg}==${ver}"
    echo >&2 "  ${arg}: ${pkg}==${ver}"
done

azcol_ver="$(get_galaxy_latest azure azcollection)"
SPECS["ANSIBLE_AZCOLLECTION_SPEC"]="azure.azcollection==${azcol_ver}"
echo >&2 "  ANSIBLE_AZCOLLECTION_SPEC: azure.azcollection==${azcol_ver}"

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

# sed -i is unusable on bind-mounted files (creates a temp file and renames).
# This helper applies a sed expression by reading into memory and writing back
# to the same inode.
sed_inplace() {
    local expr="${1}" file="${2}"
    local tmp
    tmp="$(sed "${expr}" "${file}")"
    printf '%s\n' "${tmp}" > "${file}"
}

case "${mode}" in
    --build-args)
        args=""
        for key in "${!SPECS[@]}"; do
            args+="--build-arg ${key}=${SPECS[${key}]} "
        done
        echo "${args}"
        ;;

    --update)
        dockerfile="${1:?--update requires DOCKERFILE path}"
        requirements="${2:?--update requires REQUIREMENTS_FILE path}"

        echo >&2 ""
        echo >&2 "Updating ${dockerfile}..."
        for key in "${!SPECS[@]}"; do
            sed_inplace "s|${key}=[^ \\\\]*|${key}=${SPECS[${key}]}|" "${dockerfile}"
        done

        echo >&2 "Updating ${requirements}..."
        while IFS= read -r line; do
            if [[ "${line}" == *"=="* ]]; then
                pkg="${line%%==*}"
                ver="$(get_pypi_latest "${pkg}")"
                echo >&2 "  ${pkg}==${ver}"
                sed_inplace "s|${pkg}==.*|${pkg}==${ver}|" "${requirements}"
            fi
        done <"${requirements}"

        echo >&2 ""
        echo >&2 "Done. Review changes with: git diff"
        ;;

    *)
        echo >&2 "Unknown mode: ${mode}"
        echo >&2 "Usage: resolve-versions.sh FORBIDDEN_FILE (--build-args | --update DOCKERFILE REQUIREMENTS)"
        exit 1
        ;;
esac
