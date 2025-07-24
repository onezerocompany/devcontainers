#!/usr/bin/env bash

DOCKER_VERSION="${VERSION:-"latest"}"
USE_MOBY="${MOBY:-"true"}"
MOBY_BUILDX_VERSION="${MOBYBUILDXVERSION:-"latest"}"
DOCKER_DASH_COMPOSE_VERSION="${DOCKERDASHCOMPOSEVERSION:-"v2"}"
AZURE_DNS_AUTO_DETECTION="${AZUREDNSAUTODETECTION:-"true"}"
DOCKER_DEFAULT_ADDRESS_POOL="${DOCKERDEFAULTADDRESSPOOL:-""}"
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
INSTALL_DOCKER_BUILDX="${INSTALLDOCKERBUILDX:-"true"}"
INSTALL_DOCKER_COMPOSE_SWITCH="${INSTALLDOCKERCOMPOSESWITCH:-"true"}"
INSTALL_PODMAN="${INSTALLPODMAN:-"false"}"
INSTALL_DIVE="${INSTALLDIVE:-"true"}"
INSTALL_WAIT="${INSTALLWAIT:-"true"}"
MICROSOFT_GPG_KEYS_URI="https://packages.microsoft.com/keys/microsoft.asc"
DOCKER_MOBY_ARCHIVE_VERSION_CODENAMES="bookworm buster bullseye bionic focal jammy noble"
DOCKER_LICENSED_ARCHIVE_VERSION_CODENAMES="bookworm buster bullseye bionic focal hirsute impish jammy noble"
DISABLE_IP6_TABLES="${DISABLEIP6TABLES:-false}"

set -e

rm -rf /var/lib/apt/lists/*

err() {
    echo "(!) $*" >&2
}

if [ "$(id -u)" -ne 0 ]; then
    err 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("zero" "vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

apt_get_update()
{
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "⏱️  Running apt-get update with timeout (300s)..."
        if ! timeout 300 apt-get update -y; then
            local exit_code=$?
            if [ $exit_code -eq 124 ]; then
                echo "❌ apt-get update timed out after 300 seconds"
                return 1
            else
                echo "❌ apt-get update failed"
                return 1
            fi
        fi
    fi
}

check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        echo "⏱️  Installing packages with timeout (600s): $*"
        if ! timeout 600 apt-get -y install --no-install-recommends "$@"; then
            local exit_code=$?
            if [ $exit_code -eq 124 ]; then
                echo "❌ Package installation timed out after 600 seconds"
                return 1
            else
                echo "❌ Package installation failed"
                return 1
            fi
        fi
    fi
}

find_version_from_git_tags() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository=$2
    local prefix=${3:-"tags/v"}
    local separator=${4:-"."}
    local last_part_optional=${5:-"false"}
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local escaped_separator=${separator//./\\.}
        local last_part
        if [ "${last_part_optional}" = "true" ]; then
            last_part="(${escaped_separator}[0-9]+)?"
        else
            last_part="${escaped_separator}[0-9]+"
        fi
        local regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${last_part}$"
        local version_list="$(git ls-remote --tags ${repository} | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            declare -g ${variable_name}="$(echo "${version_list}" | head -n 1)"
        else
            set +e
                declare -g ${variable_name}="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
            set -e
        fi
    fi
    if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep "^${!variable_name//./\\.}$" > /dev/null 2>&1; then
        err "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
        exit 1
    fi
    echo "${variable_name}=${!variable_name}"
}

find_prev_version_from_git_tags() {
    local variable_name=$1
    local current_version=${!variable_name}
    local repository=$2
    local prefix=${3:-"tags/v"}
    local separator=${4:-"."}
    local last_part_optional=${5:-"false"}
    local version_suffix_regex=$6
    set +e
        major="$(echo "${current_version}" | grep -oE '^[0-9]+' || echo '')"
        minor="$(echo "${current_version}" | grep -oP '^[0-9]+\.\K[0-9]+' || echo '')"
        breakfix="$(echo "${current_version}" | grep -oP '^[0-9]+\.[0-9]+\.\K[0-9]+' 2>/dev/null || echo '')"

        if [ "${minor}" = "0" ] && [ "${breakfix}" = "0" ]; then
            ((major=major-1))
            declare -g ${variable_name}="${major}"
            find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${last_part_optional}"
        elif [ "${breakfix}" = "" ] || [ "${breakfix}" = "0" ]; then
            ((minor=minor-1))
            declare -g ${variable_name}="${major}.${minor}"
            find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${last_part_optional}"
        else
            ((breakfix=breakfix-1))
            if [ "${breakfix}" = "0" ] && [ "${last_part_optional}" = "true" ]; then
                declare -g ${variable_name}="${major}.${minor}"
            else
                declare -g ${variable_name}="${major}.${minor}.${breakfix}"
            fi
        fi
    set -e
}

get_previous_version() {
    local url=$1
    local repo_url=$2
    local variable_name=$3
    prev_version=${!variable_name}

    output=$(curl -s "$repo_url");
    if echo "$output" | jq -e 'type == "object"' > /dev/null; then
      message=$(echo "$output" | jq -r '.message')

      if [[ $message == "API rate limit exceeded"* ]]; then
            echo -e "\nAn attempt to find latest version using GitHub Api Failed... \nReason: ${message}"
            echo -e "\nAttempting to find latest version using GitHub tags."
            find_prev_version_from_git_tags prev_version "$url" "tags/v"
            declare -g ${variable_name}="${prev_version}"
       fi
    elif echo "$output" | jq -e 'type == "array"' > /dev/null; then
        echo -e "\nAttempting to find latest version using GitHub Api."
        version=$(echo "$output" | jq -r '.[1].tag_name')
        declare -g ${variable_name}="${version#v}"
    fi
    echo "${variable_name}=${!variable_name}"
}

get_github_api_repo_url() {
    local url=$1
    echo "${url/https:\/\/github.com/https:\/\/api.github.com\/repos}/releases"
}

export DEBIAN_FRONTEND=noninteractive

. /etc/os-release
architecture="$(dpkg --print-architecture)"

if [ "${USE_MOBY}" = "true" ]; then
    if [[ "${DOCKER_MOBY_ARCHIVE_VERSION_CODENAMES}" != *"${VERSION_CODENAME}"* ]]; then
        err "Unsupported  distribution version '${VERSION_CODENAME}'. To resolve, either: (1) set feature option '\"moby\": false' , or (2) choose a compatible OS distribution"
        err "Support distributions include:  ${DOCKER_MOBY_ARCHIVE_VERSION_CODENAMES}"
        exit 1
    fi
    echo "Distro codename  '${VERSION_CODENAME}'  matched filter  '${DOCKER_MOBY_ARCHIVE_VERSION_CODENAMES}'"
else
    if [[ "${DOCKER_LICENSED_ARCHIVE_VERSION_CODENAMES}" != *"${VERSION_CODENAME}"* ]]; then
        err "Unsupported distribution version '${VERSION_CODENAME}'. To resolve, please choose a compatible OS distribution"
        err "Support distributions include:  ${DOCKER_LICENSED_ARCHIVE_VERSION_CODENAMES}"
        exit 1
    fi
    echo "Distro codename  '${VERSION_CODENAME}'  matched filter  '${DOCKER_LICENSED_ARCHIVE_VERSION_CODENAMES}'"
fi

check_packages apt-transport-https curl ca-certificates pigz iptables gnupg2 dirmngr wget jq
if ! type git > /dev/null 2>&1; then
    check_packages git
fi

if type iptables-legacy > /dev/null 2>&1; then
    update-alternatives --set iptables /usr/sbin/iptables-legacy
    update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
fi

if [ "${USE_MOBY}" = "true" ]; then

    engine_package_name="moby-engine"
    cli_package_name="moby-cli"

    echo "⏱️  Adding Microsoft GPG key with timeout (30s)..."
    if ! timeout 30 curl --max-time 30 --connect-timeout 10 -sSL ${MICROSOFT_GPG_KEYS_URI} | gpg --dearmor > /usr/share/keyrings/microsoft-archive-keyring.gpg; then
        echo "❌ Failed to add Microsoft GPG key (timeout or error)"
        exit 1
    fi
    echo "deb [arch=${architecture} signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/microsoft-${ID}-${VERSION_CODENAME}-prod ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/microsoft.list
else
    engine_package_name="docker-ce"
    cli_package_name="docker-ce-cli"

    echo "⏱️  Adding Docker GPG key with timeout (30s)..."
    if ! timeout 30 curl --max-time 30 --connect-timeout 10 -fsSL https://download.docker.com/linux/${ID}/gpg | gpg --dearmor > /usr/share/keyrings/docker-archive-keyring.gpg; then
        echo "❌ Failed to add Docker GPG key (timeout or error)"
        exit 1
    fi
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
fi

echo "⏱️  Updating package lists with timeout (300s)..."
if ! timeout 300 apt-get update; then
    echo "❌ apt-get update timed out after 300 seconds"
    exit 1
fi

if [ "${DOCKER_VERSION}" = "latest" ] || [ "${DOCKER_VERSION}" = "lts" ] || [ "${DOCKER_VERSION}" = "stable" ]; then
    engine_version_suffix=""
    cli_version_suffix=""
else
    docker_version_dot_escaped="${DOCKER_VERSION//./\\.}"
    docker_version_dot_plus_escaped="${docker_version_dot_escaped//+/\\+}"
    docker_version_regex="^(.+:)?${docker_version_dot_plus_escaped}([\.\\+ ~:-]|$)"
    set +e
        cli_version_suffix="=$(apt-cache madison ${cli_package_name} | awk -F"|" '{print $2}' | sed -e 's/^[ \t]*//' | grep -E -m 1 "${docker_version_regex}")"
        engine_version_suffix="=$(apt-cache madison ${engine_package_name} | awk -F"|" '{print $2}' | sed -e 's/^[ \t]*//' | grep -E -m 1 "${docker_version_regex}")"
    set -e
    if [ -z "${engine_version_suffix}" ] || [ "${engine_version_suffix}" = "=" ] || [ -z "${cli_version_suffix}" ] || [ "${cli_version_suffix}" = "=" ] ; then
        err "No full or partial Docker / Moby version match found for \"${DOCKER_VERSION}\" on OS ${ID} ${VERSION_CODENAME} (${architecture}). Available versions:"
        apt-cache madison ${cli_package_name} | awk -F"|" '{print $2}' | grep -oP '^(.+:)?\K.+'
        exit 1
    fi
    echo "engine_version_suffix ${engine_version_suffix}"
    echo "cli_version_suffix ${cli_version_suffix}"
fi

if [ "${USE_MOBY}" = "true" ]; then
    if [ "${MOBY_BUILDX_VERSION}" = "latest" ]; then
        buildx_version_suffix=""
    else
        buildx_version_dot_escaped="${MOBY_BUILDX_VERSION//./\\.}"
        buildx_version_dot_plus_escaped="${buildx_version_dot_escaped//+/\\+}"
        buildx_version_regex="^(.+:)?${buildx_version_dot_plus_escaped}([\.\\+ ~:-]|$)"
        set +e
            buildx_version_suffix="=$(apt-cache madison moby-buildx | awk -F"|" '{print $2}' | sed -e 's/^[ \t]*//' | grep -E -m 1 "${buildx_version_regex}")"
        set -e
        if [ -z "${buildx_version_suffix}" ] || [ "${buildx_version_suffix}" = "=" ]; then
            err "No full or partial moby-buildx version match found for \"${MOBY_BUILDX_VERSION}\" on OS ${ID} ${VERSION_CODENAME} (${architecture}). Available versions:"
            apt-cache madison moby-buildx | awk -F"|" '{print $2}' | grep -oP '^(.+:)?\K.+'
            exit 1
        fi
        echo "buildx_version_suffix ${buildx_version_suffix}"
    fi
fi

if type docker > /dev/null 2>&1 && type dockerd > /dev/null 2>&1; then
    echo "Docker / Moby CLI and Engine already installed."
else
    if [ "${USE_MOBY}" = "true" ]; then
        set +e
            echo "⏱️  Installing Moby packages with timeout (900s)..."
            timeout 900 apt-get -y install --no-install-recommends moby-cli${cli_version_suffix} moby-buildx${buildx_version_suffix} moby-engine${engine_version_suffix}
            exit_code=$?
        set -e

        if [ ${exit_code} -ne 0 ]; then
            err "Packages for moby not available in OS ${ID} ${VERSION_CODENAME} (${architecture}). To resolve, either: (1) set feature option '\"moby\": false' , or (2) choose a compatible OS version (eg: 'ubuntu-20.04')."
            exit 1
        fi

        echo "⏱️  Installing moby-compose with timeout (300s)..."
        timeout 300 apt-get -y install --no-install-recommends moby-compose || err "Package moby-compose (Docker Compose v2) not available for OS ${ID} ${VERSION_CODENAME} (${architecture}). Skipping."
    else
        echo "⏱️  Installing Docker CE packages with timeout (900s)..."
        if ! timeout 900 apt-get -y install --no-install-recommends docker-ce-cli${cli_version_suffix} docker-ce${engine_version_suffix}; then
            echo "❌ Docker CE installation timed out or failed"
            exit 1
        fi
        apt-mark hold docker-ce docker-ce-cli
        apt-get -y install --no-install-recommends docker-compose-plugin || echo "(*) Package docker-compose-plugin (Docker Compose v2) not available for OS ${ID} ${VERSION_CODENAME} (${architecture}). Skipping."
    fi
fi

echo "Finished installing docker / moby!"

docker_home="/usr/libexec/docker"
cli_plugins_dir="${docker_home}/cli-plugins"

fallback_compose(){
    local url=$1
    local repo_url=$(get_github_api_repo_url "$url")
    echo -e "\n(!) Failed to fetch the latest artifacts for docker-compose v${compose_version}..."
    get_previous_version "${url}" "${repo_url}" compose_version
    echo -e "\nAttempting to install v${compose_version}"
    curl -fsSL "https://github.com/docker/compose/releases/download/v${compose_version}/docker-compose-linux-${target_compose_arch}" -o ${docker_compose_path}
}

if [ "${DOCKER_DASH_COMPOSE_VERSION}" != "none" ]; then
    case "${architecture}" in
        amd64) target_compose_arch=x86_64 ;;
        arm64) target_compose_arch=aarch64 ;;
        *)
            echo "(!) Docker in docker does not support machine architecture '$architecture'. Please use an x86-64 or ARM64 machine."
            exit 1
    esac

    docker_compose_path="/usr/local/bin/docker-compose"
    if [ "${DOCKER_DASH_COMPOSE_VERSION}" = "v1" ]; then
        err "The final Compose V1 release, version 1.29.2, was May 10, 2021. These packages haven't received any security updates since then. Use at your own risk."
        INSTALL_DOCKER_COMPOSE_SWITCH="false"

        if [ "${target_compose_arch}" = "x86_64" ]; then
            echo "(*) Installing docker compose v1..."
            curl -fsSL "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64" -o ${docker_compose_path}
            chmod +x ${docker_compose_path}

            DOCKER_COMPOSE_SHA256="$(curl -sSL "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64.sha256" | awk '{print $1}')"
            echo "${DOCKER_COMPOSE_SHA256}  ${docker_compose_path}" > docker-compose.sha256sum
            sha256sum -c docker-compose.sha256sum --ignore-missing
        elif [ "${VERSION_CODENAME}" = "bookworm" ]; then
            err "Docker compose v1 is unavailable for 'bookworm' on Arm64. Kindly switch to use v2"
            exit 1
        else
            check_packages python3-minimal python3-pip libffi-dev python3-venv
            echo "(*) Installing docker compose v1 via pip..."
            export PYTHONUSERBASE=/usr/local
            pip3 install --disable-pip-version-check --no-cache-dir --user "Cython<3.0" pyyaml wheel docker-compose --no-build-isolation
        fi
    else
        compose_version=${DOCKER_DASH_COMPOSE_VERSION#v}
        docker_compose_url="https://github.com/docker/compose"
        find_version_from_git_tags compose_version "$docker_compose_url" "tags/v"
        echo "(*) Installing docker-compose ${compose_version}..."
        echo "⏱️  Downloading docker-compose with timeout (60s)..."
        timeout 60 curl --max-time 60 --connect-timeout 10 -fsSL "https://github.com/docker/compose/releases/download/v${compose_version}/docker-compose-linux-${target_compose_arch}" -o ${docker_compose_path} || {
                 echo -e "\n(!) Failed to fetch the latest artifacts for docker-compose v${compose_version}..."
                 fallback_compose "$docker_compose_url"
        }

        chmod +x ${docker_compose_path}

        DOCKER_COMPOSE_SHA256="$(curl -sSL "https://github.com/docker/compose/releases/download/v${compose_version}/docker-compose-linux-${target_compose_arch}.sha256" | awk '{print $1}')"
        echo "${DOCKER_COMPOSE_SHA256}  ${docker_compose_path}" > docker-compose.sha256sum
        sha256sum -c docker-compose.sha256sum --ignore-missing

        mkdir -p ${cli_plugins_dir}
        cp ${docker_compose_path} ${cli_plugins_dir}
    fi
fi

fallback_compose-switch() {
    local url=$1
    local repo_url=$(get_github_api_repo_url "$url")
    echo -e "\n(!) Failed to fetch the latest artifacts for compose-switch v${compose_switch_version}..."
    get_previous_version "$url" "$repo_url" compose_switch_version
    echo -e "\nAttempting to install v${compose_switch_version}"
    curl -fsSL "https://github.com/docker/compose-switch/releases/download/v${compose_switch_version}/docker-compose-linux-${architecture}" -o /usr/local/bin/compose-switch
}

if [ "${INSTALL_DOCKER_COMPOSE_SWITCH}" = "true" ] && ! type compose-switch > /dev/null 2>&1; then
    if type docker-compose > /dev/null 2>&1; then
        echo "(*) Installing compose-switch..."
        current_compose_path="$(which docker-compose)"
        target_compose_path="$(dirname "${current_compose_path}")/docker-compose-v1"
        compose_switch_version="latest"
        compose_switch_url="https://github.com/docker/compose-switch"
        find_version_from_git_tags compose_switch_version "$compose_switch_url"
        curl -fsSL "https://github.com/docker/compose-switch/releases/download/v${compose_switch_version}/docker-compose-linux-${architecture}" -o /usr/local/bin/compose-switch || fallback_compose-switch "$compose_switch_url"
        chmod +x /usr/local/bin/compose-switch
        mv "${current_compose_path}" "${target_compose_path}"
        update-alternatives --install ${docker_compose_path} docker-compose /usr/local/bin/compose-switch 99
        update-alternatives --install ${docker_compose_path} docker-compose "${target_compose_path}" 1
    else
        err "Skipping installation of compose-switch as docker compose is unavailable..."
    fi
fi

if [ -f "/usr/local/share/docker-init.sh" ]; then
    echo "/usr/local/share/docker-init.sh already exists, so exiting."
    rm -rf /var/lib/apt/lists/*
    exit 0
fi
echo "docker-init doesn't exist, adding..."

if ! cat /etc/group | grep -e "^docker:" > /dev/null 2>&1; then
        groupadd -r docker
fi

usermod -aG docker ${USERNAME}

fallback_buildx() {
    local url=$1
    local repo_url=$(get_github_api_repo_url "$url")
    echo -e "\n(!) Failed to fetch the latest artifacts for docker buildx v${buildx_version}..."
    get_previous_version "$url" "$repo_url" buildx_version
    buildx_file_name="buildx-v${buildx_version}.linux-${architecture}"
    echo -e "\nAttempting to install v${buildx_version}"
    wget https://github.com/docker/buildx/releases/download/v${buildx_version}/${buildx_file_name}
}

if [ "${INSTALL_DOCKER_BUILDX}" = "true" ]; then
    buildx_version="latest"
    docker_buildx_url="https://github.com/docker/buildx"
    find_version_from_git_tags buildx_version "$docker_buildx_url" "refs/tags/v"
    echo "(*) Installing buildx ${buildx_version}..."
    buildx_file_name="buildx-v${buildx_version}.linux-${architecture}"

    cd /tmp
    wget https://github.com/docker/buildx/releases/download/v${buildx_version}/${buildx_file_name} || fallback_buildx "$docker_buildx_url"

    docker_home="/usr/libexec/docker"
    cli_plugins_dir="${docker_home}/cli-plugins"

    mkdir -p ${cli_plugins_dir}
    mv ${buildx_file_name} ${cli_plugins_dir}/docker-buildx
    chmod +x ${cli_plugins_dir}/docker-buildx

    chown -R "${USERNAME}:docker" "${docker_home}"
    chmod -R g+r+w "${docker_home}"
    find "${docker_home}" -type d -print0 | xargs -n 1 -0 chmod g+s
fi

DOCKER_DEFAULT_IP6_TABLES=""
if [ "$DISABLE_IP6_TABLES" == true ]; then
    requested_version=""
    semver_regex="^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$"
    if echo "$DOCKER_VERSION" | grep -Eq $semver_regex; then
        requested_version=$(echo $DOCKER_VERSION | cut -d. -f1)
    elif echo "$DOCKER_VERSION" | grep -Eq "^[1-9][0-9]*$"; then
        requested_version=$DOCKER_VERSION
    fi
    if [ "$DOCKER_VERSION" = "latest" ] || [[ -n "$requested_version" && "$requested_version" -ge 27 ]] ; then
        DOCKER_DEFAULT_IP6_TABLES="--ip6tables=false"
        echo "(!) As requested, passing '${DOCKER_DEFAULT_IP6_TABLES}'"
    fi
fi

tee /usr/local/share/docker-init.sh > /dev/null \
<< EOF
#!/bin/sh

set -e

AZURE_DNS_AUTO_DETECTION=${AZURE_DNS_AUTO_DETECTION}
DOCKER_DEFAULT_ADDRESS_POOL=${DOCKER_DEFAULT_ADDRESS_POOL}
DOCKER_DEFAULT_IP6_TABLES=${DOCKER_DEFAULT_IP6_TABLES}
EOF

tee -a /usr/local/share/docker-init.sh > /dev/null \
<< 'EOF'
dockerd_start="AZURE_DNS_AUTO_DETECTION=${AZURE_DNS_AUTO_DETECTION} DOCKER_DEFAULT_ADDRESS_POOL=${DOCKER_DEFAULT_ADDRESS_POOL} DOCKER_DEFAULT_IP6_TABLES=${DOCKER_DEFAULT_IP6_TABLES} $(cat << 'INNEREOF'
    find /run /var/run -iname 'docker*.pid' -delete || :
    find /run /var/run -iname 'container*.pid' -delete || :

    export container=docker

    if [ -d /sys/kernel/security ] && ! mountpoint -q /sys/kernel/security; then
        mount -t securityfs none /sys/kernel/security || {
            echo >&2 'Could not mount /sys/kernel/security.'
            echo >&2 'AppArmor detection and --privileged mode might break.'
        }
    fi

    if ! mountpoint -q /tmp; then
        mount -t tmpfs none /tmp
    fi

    set_cgroup_nesting()
    {
        if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
            mkdir -p /sys/fs/cgroup/init
            xargs -rn1 < /sys/fs/cgroup/cgroup.procs > /sys/fs/cgroup/init/cgroup.procs || :
            sed -e 's/ / +/g' -e 's/^/+/' < /sys/fs/cgroup/cgroup.controllers \
                > /sys/fs/cgroup/cgroup.subtree_control
        fi
    }

    retry_cgroup_nesting=0

    until [ "${retry_cgroup_nesting}" -eq "5" ];
    do
        set +e
            set_cgroup_nesting

            if [ $? -ne 0 ]; then
                echo "(*) cgroup v2: Failed to enable nesting, retrying..."
            else
                break
            fi

            retry_cgroup_nesting=`expr $retry_cgroup_nesting + 1`
        set -e
    done

    set +e
        cat /etc/resolv.conf | grep -i 'internal.cloudapp.net' > /dev/null 2>&1
        if [ $? -eq 0 ] && [ "${AZURE_DNS_AUTO_DETECTION}" = "true" ]
        then
            echo "Setting dockerd Azure DNS."
            CUSTOMDNS="--dns 168.63.129.16"
        else
            echo "Not setting dockerd DNS manually."
            CUSTOMDNS=""
        fi
    set -e

    if [ -z "$DOCKER_DEFAULT_ADDRESS_POOL" ]
    then
        DEFAULT_ADDRESS_POOL=""
    else
        DEFAULT_ADDRESS_POOL="--default-address-pool $DOCKER_DEFAULT_ADDRESS_POOL"
    fi

    ( dockerd $CUSTOMDNS $DEFAULT_ADDRESS_POOL $DOCKER_DEFAULT_IP6_TABLES > /tmp/dockerd.log 2>&1 ) &
INNEREOF
)"

sudo_if() {
    COMMAND="$*"

    if [ "$(id -u)" -ne 0 ]; then
        sudo $COMMAND
    else
        $COMMAND
    fi
}

retry_docker_start_count=0
docker_ok="false"

until [ "${docker_ok}" = "true"  ] || [ "${retry_docker_start_count}" -eq "5" ];
do
    if [ "$(id -u)" -ne 0 ]; then
        sudo /bin/sh -c "${dockerd_start}"
    else
        eval "${dockerd_start}"
    fi

    retry_count=0
    until [ "${docker_ok}" = "true"  ] || [ "${retry_count}" -eq "5" ];
    do
        sleep 1s
        set +e
            docker info > /dev/null 2>&1 && docker_ok="true"
        set -e

        retry_count=`expr $retry_count + 1`
    done

    if [ "${docker_ok}" != "true" ] && [ "${retry_docker_start_count}" != "4" ]; then
        echo "(*) Failed to start docker, retrying..."
        set +e
            sudo_if pkill dockerd
            sudo_if pkill containerd
        set -e
    fi

    retry_docker_start_count=`expr $retry_docker_start_count + 1`
done

exec "$@"
EOF

chmod +x /usr/local/share/docker-init.sh
chown ${USERNAME}:root /usr/local/share/docker-init.sh

# ========================================
# CONTAINER TOOLS INSTALLATION
# ========================================

echo "Installing additional container tools..."

# Get system architecture
ARCH=$(dpkg --print-architecture)

# Install Podman tools if enabled
if [ "$INSTALL_PODMAN" = "true" ]; then
    echo "📦 Installing Podman and related tools..."
    container_packages="podman buildah skopeo"
    apt_get_update
    apt-get install -y $container_packages
    echo "  ✓ Podman tools installed successfully"
fi

# Install dive for Docker image analysis if enabled
if [ "$INSTALL_DIVE" = "true" ]; then
    echo "📦 Installing dive for Docker image analysis..."
    DIVE_VERSION="0.12.0"
    case $ARCH in
        amd64) DIVE_ARCH="amd64" ;;
        arm64) DIVE_ARCH="arm64" ;;
        *) echo "  ⚠️  Unsupported architecture for dive: $ARCH, skipping"; DIVE_ARCH="" ;;
    esac
    
    if [ -n "$DIVE_ARCH" ]; then
        DIVE_URL="https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_${DIVE_ARCH}.deb"
        echo "  Downloading dive from: $DIVE_URL"
        if curl -fsSL "$DIVE_URL" -o /tmp/dive.deb; then
            if dpkg -i /tmp/dive.deb || apt-get install -f -y; then
                echo "  ✓ dive installed successfully"
            else
                echo "  ⚠️  Failed to install dive package"
            fi
            rm -f /tmp/dive.deb
        else
            echo "  ⚠️  Failed to download dive, skipping"
            rm -f /tmp/dive.deb
        fi
    fi
fi

# Install docker-compose-wait utility if enabled
if [ "$INSTALL_WAIT" = "true" ]; then
    echo "📦 Installing docker-compose-wait utility..."
    WAIT_URL="https://github.com/ufoscout/docker-compose-wait/releases/download/2.12.1/wait"
    echo "  Downloading docker-compose-wait from: $WAIT_URL"
    if curl -fsSL "$WAIT_URL" -o /usr/local/bin/docker-compose-wait; then
        chmod +x /usr/local/bin/docker-compose-wait
        echo "  ✓ docker-compose-wait installed successfully"
    else
        echo "  ⚠️  Failed to download docker-compose-wait, skipping"
        rm -f /usr/local/bin/docker-compose-wait
    fi
fi

# Setup container aliases and configurations
echo "🔧 Setting up container tools configuration..."

# Create shell aliases file
mkdir -p /usr/local/share/docker-aliases
cat > /usr/local/share/docker-aliases/aliases.sh << 'EOF'
# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcd='docker-compose down'
alias dcl='docker-compose logs'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias drmf='docker rm -f'
alias drmi='docker rmi'
alias dprune='docker system prune -f'
alias dshell='docker run --rm -it'
alias dexec='docker exec -it'
alias dbuild='docker build'
alias dtag='docker tag'
alias dpush='docker push'
alias dpull='docker pull'
EOF

# Add aliases to shell configurations
add_aliases_to_shell() {
    local shell_file="$1"
    local marker_start="# >>> Docker Aliases - START >>>"
    local marker_end="# <<< Docker Aliases - END <<<"
    
    if [ -f "$shell_file" ] && ! grep -q "$marker_start" "$shell_file"; then
        echo "" >> "$shell_file"
        echo "$marker_start" >> "$shell_file"
        echo "# Docker container aliases" >> "$shell_file"
        echo "[ -f /usr/local/share/docker-aliases/aliases.sh ] && source /usr/local/share/docker-aliases/aliases.sh" >> "$shell_file"
        echo "$marker_end" >> "$shell_file"
        echo "  Added Docker aliases to $(basename "$shell_file")"
    fi
}

# Apply aliases to user shells
if [ "$USERNAME" != "root" ]; then
    USER_HOME="/home/$USERNAME"
    add_aliases_to_shell "$USER_HOME/.bashrc"
    add_aliases_to_shell "$USER_HOME/.zshrc"
    
    # Set ownership
    chown -R "$USERNAME:$USERNAME" "$USER_HOME/.bashrc" "$USER_HOME/.zshrc" 2>/dev/null || true
fi

# Apply aliases to root shells
add_aliases_to_shell "/root/.bashrc"
add_aliases_to_shell "/root/.zshrc"

echo "✅ Container tools configuration completed"

rm -rf /var/lib/apt/lists/*

echo 'docker-in-docker-debian script has completed!'