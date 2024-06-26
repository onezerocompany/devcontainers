#!/bin/bash -e

INSTALL=${INSTALL:-"true"}
TERRAFORM_VERSION="${VERSION:-"latest"}"
TFLINT_VERSION="${TFLINT:-"latest"}"
INSTALL_TERRAFORM_DOCS=${INSTALLTERRAFORMDOCS:-false}
INSTALL_TF_SUMMARIZE=${INSTALLTFSUMMARIZE:-false}

TERRAFORM_SHA256="${TERRAFORM_SHA256:-"automatic"}"
TFLINT_SHA256="${TFLINT_SHA256:-"automatic"}"
TERRAFORM_DOCS_SHA256="${TERRAFORM_DOCS_SHA256:-"automatic"}"

TERRAFORM_GPG_KEY="72D7468F"
TFLINT_GPG_KEY_URI="https://raw.githubusercontent.com/terraform-linters/tflint/v0.46.1/8CE69160EB3F2FE9.key"
GPG_KEY_SERVERS="keyserver hkps://keyserver.ubuntu.com
keyserver hkps://keys.openpgp.org
keyserver hkps://keyserver.pgp.com"
KEYSERVER_PROXY="${HTTPPROXY:-"${HTTP_PROXY:-""}"}"

if [ "$INSTALL" != "true" ]; then
    echo "Skipping Terraform installation"
    exit 0
fi

architecture="$(uname -m)"
case ${architecture} in
    x86_64) architecture="amd64";;
    aarch64 | armv8*) architecture="arm64";;
    aarch32 | armv7* | armvhf*) architecture="arm";;
    i?86) architecture="386";;
    *) echo "(!) Architecture ${architecture} unsupported"; exit 1 ;;
esac

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Import the specified key in a variable name passed in as 
receive_gpg_keys() {
    local keys=${!1}
    local keyring_args=""
    if [ ! -z "$2" ]; then
        keyring_args="--no-default-keyring --keyring $2"
    fi
    if [ ! -z "${KEYSERVER_PROXY}" ]; then
	keyring_args="${keyring_args} --keyserver-options http-proxy=${KEYSERVER_PROXY}"
    fi

    # Use a temporary location for gpg keys to avoid polluting image
    export GNUPGHOME="/tmp/tmp-gnupg"
    mkdir -p ${GNUPGHOME}
    chmod 700 ${GNUPGHOME}
    echo -e "disable-ipv6\n${GPG_KEY_SERVERS}" > ${GNUPGHOME}/dirmngr.conf
    # GPG key download sometimes fails for some reason and retrying fixes it.
    local retry_count=0
    local gpg_ok="false"
    set +e
    until [ "${gpg_ok}" = "true" ] || [ "${retry_count}" -eq "5" ]; 
    do
        echo "(*) Downloading GPG key..."
        ( echo "${keys}" | xargs -n 1 gpg -q ${keyring_args} --recv-keys) 2>&1 && gpg_ok="true"
        if [ "${gpg_ok}" != "true" ]; then
            echo "(*) Failed getting key, retring in 10s..."
            (( retry_count++ ))
            sleep 10s
        fi
    done

    # If all attempts fail, try getting the keyserver IP address and explicitly passing it to gpg
    if [ "${gpg_ok}" = "false" ]; then
        retry_count=0;
        echo "(*) Resolving GPG keyserver IP address..."
        local keyserver_ip_address=$( dig +short keyserver.ubuntu.com | head -n1 )
        echo "(*) GPG keyserver IP address $keyserver_ip_address"
        
        until [ "${gpg_ok}" = "true" ] || [ "${retry_count}" -eq "3" ]; 
        do
            echo "(*) Downloading GPG key..."
            ( echo "${keys}" | xargs -n 1 gpg -q ${keyring_args} --recv-keys --keyserver ${keyserver_ip_address}) 2>&1 && gpg_ok="true"
            if [ "${gpg_ok}" != "true" ]; then
                echo "(*) Failed getting key, retring in 10s..."
                (( retry_count++ ))
                sleep 10s
            fi
        done
    fi
    set -e
    if [ "${gpg_ok}" = "false" ]; then
        echo "(!) Failed to get gpg key."
        exit 1
    fi
}

# Figure out correct version of a three part version number is not passed
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
        echo -e "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
        exit 1
    fi
    echo "${variable_name}=${!variable_name}"
}

# Use semver logic to decrement a version number then look for the closest match
find_prev_version_from_git_tags() {
    local variable_name=$1
    local current_version=${!variable_name}
    local repository=$2
    # Normally a "v" is used before the version number, but support alternate cases
    local prefix=${3:-"tags/v"}
    # Some repositories use "_" instead of "." for version number part separation, support that
    local separator=${4:-"."}
    # Some tools release versions that omit the last digit (e.g. go)
    local last_part_optional=${5:-"false"}
    # Some repositories may have tags that include a suffix (e.g. actions/node-versions)
    local version_suffix_regex=$6
    # Try one break fix version number less if we get a failure. Use "set +e" since "set -e" can cause failures in valid scenarios.
    set +e
        major="$(echo "${current_version}" | grep -oE '^[0-9]+' || echo '')"
        minor="$(echo "${current_version}" | grep -oP '^[0-9]+\.\K[0-9]+' || echo '')"
        breakfix="$(echo "${current_version}" | grep -oP '^[0-9]+\.[0-9]+\.\K[0-9]+' 2>/dev/null || echo '')"

        if [ "${minor}" = "0" ] && [ "${breakfix}" = "0" ]; then
            ((major=major-1))
            declare -g ${variable_name}="${major}"
            # Look for latest version from previous major release
            find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${last_part_optional}"
        # Handle situations like Go's odd version pattern where "0" releases omit the last part
        elif [ "${breakfix}" = "" ] || [ "${breakfix}" = "0" ]; then
            ((minor=minor-1))
            declare -g ${variable_name}="${major}.${minor}"
            # Look for latest version from previous minor release
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

apt_get_update()
{
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Function to fetch the version released prior to the latest version
get_previous_version() {
    local url=$1
    local repo_url=$2
    local variable_name=$3
    prev_version=${!variable_name}
    
    output=$(curl -s "$repo_url");

    # install jq
    check_packages jq
    
    message=$(echo "$output" | jq -r '.message')
    
    if [[ $message == "API rate limit exceeded"* ]]; then
        echo -e "\nAn attempt to find latest version using GitHub Api Failed... \nReason: ${message}"
        echo -e "\nAttempting to find latest version using GitHub tags."
        find_prev_version_from_git_tags prev_version "$url" "tags/v"
        declare -g ${variable_name}="${prev_version}"
    else
        echo -e "\nAttempting to find latest version using GitHub Api."
        version=$(echo "$output" | jq -r '.tag_name')
        declare -g ${variable_name}="${version#v}"
    fi  
    echo "${variable_name}=${!variable_name}"
}

get_github_api_repo_url() {
    local url=$1
    echo "${url/https:\/\/github.com/https:\/\/api.github.com\/repos}/releases/latest"
}

install_previous_version() {
    given_version=$1
    requested_version=${!given_version}
    local URL=$2
    INSTALLER_FN=$3
    local REPO_URL=$(get_github_api_repo_url "$URL")
    local PKG_NAME=$(get_pkg_name "${given_version}")
    echo -e "\n(!) Failed to fetch the latest artifacts for ${PKG_NAME} v${requested_version}..."
    get_previous_version "$URL" "$REPO_URL" requested_version
    echo -e "\nAttempting to install ${requested_version}"
    declare -g ${given_version}="${requested_version#v}"
    $INSTALLER_FN "${!given_version}"
    echo "${given_version}=${!given_version}"
}

install_cosign() {
    COSIGN_VERSION=$1
    local URL=$2
    cosign_filename="/tmp/cosign_${COSIGN_VERSION}_${architecture}.deb"
    cosign_url="https://github.com/sigstore/cosign/releases/latest/download/cosign_${COSIGN_VERSION}_${architecture}.deb"
    curl -L "${cosign_url}" -o $cosign_filename
    if grep -q "Not Found" "$cosign_filename"; then
        echo -e "\n(!) Failed to fetch the latest artifacts for cosign v${COSIGN_VERSION}..."
        REPO_URL=$(get_github_api_repo_url "$URL")
        get_previous_version "$URL" "$REPO_URL" COSIGN_VERSION
        echo -e "\nAttempting to install ${COSIGN_VERSION}"
        cosign_filename="/tmp/cosign_${COSIGN_VERSION}_${architecture}.deb"
        cosign_url="https://github.com/sigstore/cosign/releases/latest/download/cosign_${COSIGN_VERSION}_${architecture}.deb"
        curl -L "${cosign_url}" -o $cosign_filename
    fi
    dpkg -i $cosign_filename
    rm $cosign_filename
    echo "Installation of cosign succeeded with ${COSIGN_VERSION}."
}

# Install 'cosign' for validating signatures
# https://docs.sigstore.dev/cosign/overview/
ensure_cosign() {
    check_packages curl ca-certificates gnupg2

    if ! type cosign > /dev/null 2>&1; then
        echo "Installing cosign..."
        COSIGN_VERSION="latest"
        cosign_url='https://github.com/sigstore/cosign'
        find_version_from_git_tags COSIGN_VERSION "${cosign_url}"
        install_cosign "${COSIGN_VERSION}" "${cosign_url}"
    fi
    if ! type cosign > /dev/null 2>&1; then
        echo "(!) Failed to install cosign."
        exit 1
    fi
    cosign version
}

# Ensure apt is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

# Install dependencies if missing
check_packages curl ca-certificates gnupg2 dirmngr coreutils unzip dnsutils
if ! type git > /dev/null 2>&1; then
    check_packages git
fi

terraform_url='https://github.com/hashicorp/terraform'
tflint_url='https://github.com/terraform-linters/tflint'
# Verify requested version is available, convert latest
find_version_from_git_tags TERRAFORM_VERSION "$terraform_url"
find_version_from_git_tags TFLINT_VERSION "$tflint_url"

install_terraform() {
    local TERRAFORM_VERSION=$1
    terraform_filename="terraform_${TERRAFORM_VERSION}_linux_${architecture}.zip"
    curl -sSL -o ${terraform_filename} "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${terraform_filename}"
}

mkdir -p /tmp/tf-downloads
cd /tmp/tf-downloads
# Install Terraform, tflint
echo "Downloading terraform..."
terraform_filename="terraform_${TERRAFORM_VERSION}_linux_${architecture}.zip"
install_terraform "$TERRAFORM_VERSION"
if grep -q "The specified key does not exist." "${terraform_filename}"; then
    install_previous_version TERRAFORM_VERSION $terraform_url "install_terraform"
    terraform_filename="terraform_${TERRAFORM_VERSION}_linux_${architecture}.zip"
fi
if [ "${TERRAFORM_SHA256}" != "dev-mode" ]; then
    if [ "${TERRAFORM_SHA256}" = "automatic" ]; then
        receive_gpg_keys TERRAFORM_GPG_KEY
        curl -sSL -o terraform_SHA256SUMS https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS 
        curl -sSL -o terraform_SHA256SUMS.sig https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.${TERRAFORM_GPG_KEY}.sig
        gpg --verify terraform_SHA256SUMS.sig terraform_SHA256SUMS
    else
        echo "${TERRAFORM_SHA256} *${terraform_filename}" > terraform_SHA256SUMS
    fi
    sha256sum --ignore-missing -c terraform_SHA256SUMS
fi
unzip ${terraform_filename}
mv -f terraform /usr/local/bin/

install_tflint() {
    TFLINT_VERSION=$1
    curl -sSL -o /tmp/tf-downloads/${TFLINT_FILENAME} https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/${TFLINT_FILENAME}
}

if [ "${TFLINT_VERSION}" != "none" ]; then
    echo "Downloading tflint..."
    TFLINT_FILENAME="tflint_linux_${architecture}.zip"
    install_tflint "$TFLINT_VERSION"
    if grep -q "Not Found" "/tmp/tf-downloads/${TFLINT_FILENAME}"; then 
        install_previous_version TFLINT_VERSION "$tflint_url" "install_tflint"
    fi
    if [ "${TFLINT_SHA256}" != "dev-mode" ]; then

        if [ "${TFLINT_SHA256}" != "automatic" ]; then
            echo "${TFLINT_SHA256} *${TFLINT_FILENAME}" > tflint_checksums.txt
            sha256sum --ignore-missing -c tflint_checksums.txt
        else
            curl -sSL -o tflint_checksums.txt https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/checksums.txt

            set +e
            curl -sSL -o checksums.txt.keyless.sig https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/checksums.txt.keyless.sig
            set -e

            # Check that checksums.txt.keyless.sig exists and is not empty
            if [ -s checksums.txt.keyless.sig ]; then
                # Validate checksums with cosign
                curl -sSL -o checksums.txt.pem https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/checksums.txt.pem
                ensure_cosign
                cosign verify-blob \
                    --certificate=/tmp/tf-downloads/checksums.txt.pem \
                    --signature=/tmp/tf-downloads/checksums.txt.keyless.sig \
                    --certificate-identity-regexp="^https://github.com/terraform-linters/tflint"  \
                    --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
                    /tmp/tf-downloads/tflint_checksums.txt
                # Ensure that checksums.txt has $TFLINT_FILENAME
                grep ${TFLINT_FILENAME} /tmp/tf-downloads/tflint_checksums.txt
                # Validate downloaded file
                sha256sum --ignore-missing -c tflint_checksums.txt
            else
                # Fallback to older, GPG-based verification (pre-0.47.0 of tflint)
                curl -sSL -o tflint_checksums.txt.sig https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/checksums.txt.sig
                curl -sSL -o tflint_key "${TFLINT_GPG_KEY_URI}"
                gpg -q --import tflint_key
                gpg --verify tflint_checksums.txt.sig tflint_checksums.txt
            fi
        fi
    fi

    unzip /tmp/tf-downloads/${TFLINT_FILENAME}
    mv -f tflint /usr/local/bin/
fi

install_terraform_docs() {
    local TERRAFORM_DOCS_VERSION=$1
    tfdocs_filename="terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-${architecture}.tar.gz"
    curl -sSL -o /tmp/tf-downloads/${tfdocs_filename} https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/${tfdocs_filename}
}

if [ "${INSTALL_TERRAFORM_DOCS}" = "true" ]; then
    TERRAFORM_DOCS_VERSION="latest"
    terraform_docs_url='https://github.com/terraform-docs/terraform-docs'
    find_version_from_git_tags TERRAFORM_DOCS_VERSION $terraform_docs_url
    tfdocs_filename="terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-${architecture}.tar.gz"
    echo "(*) Downloading Terraform docs... ${tfdocs_filename}"
    install_terraform_docs "$TERRAFORM_DOCS_VERSION"
    if grep -q "Not Found" "/tmp/tf-downloads/${tfdocs_filename}"; then
        install_previous_version TERRAFORM_DOCS_VERSION $terraform_docs_url "install_terraform_docs"
        tfdocs_filename="terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-${architecture}.tar.gz"
    fi
    if [ "${TERRAFORM_DOCS_SHA256}" != "dev-mode" ]; then
        if [ "${TERRAFORM_DOCS_SHA256}" = "automatic" ]; then
            curl -sSL -o tfdocs_SHA256SUMS https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}.sha256sum
        else
            echo "${TERRAFORM_DOCS_SHA256}" > tfdocs_SHA256SUMS
        fi
        sha256sum --ignore-missing -c tfdocs_SHA256SUMS
    fi
    mkdir -p /tmp/tf-downloads/tfdocs
    tar -xzf /tmp/tf-downloads/${tfdocs_filename} -C /tmp/tf-downloads/tfdocs
    chmod a+x /tmp/tf-downloads/tfdocs/terraform-docs
    mv -f /tmp/tf-downloads/tfdocs/terraform-docs /usr/local/bin/terraform-docs
fi

function find_latest_tf_summarize_version() {
    project_url="https://github.com/dineshba/tf-summarize"

    latest_release=$(curl -sL https://api.github.com/repos/dineshba/tf-summarize/releases/latest)

    if [ -z "$latest_release" ]; then
        echo "Failed to fetch release information."
        return 1  # Return an error code 
    fi

    echo "$latest_release" | jq -r '.tag_name' | sed 's/v//'
}

if [ "${INSTALL_TF_SUMMARIZE}" = "true" ]; then
    echo "Installing tf-summarize..."
    check_packages jq
    tf_summarize_version=$(find_latest_tf_summarize_version)
    download_url="https://github.com/dineshba/tf-summarize/releases/download/v$tf_summarize_version/tf-summarize_${tf_summarize_version}_linux_${architecture}.deb"

    curl -sSL -o /tmp/tf-downloads/tf-summarize.deb $download_url
    dpkg -i /tmp/tf-downloads/tf-summarize.deb

    if ! type tf-summarize > /dev/null 2>&1; then
        echo "(!) Failed to install tf-summarize."
        exit 1
    fi

    echo "tf-summarize installed successfully."
fi

# add alias for terraform (tf) to zsh and bash profile of 'zero' user
USER=${USER:-"zero"}
ZSHRC="$(su $USER -c 'echo $HOME')/.zshrc"
BASHRC="$(su $USER -c 'echo $HOME')/.bashrc"

if [ -f $ZSHRC ]; then
    echo "Adding terraform alias to zshrc"
    echo "alias tf='terraform'" >> $ZSHRC
fi

if [ -f $BASHRC ]; then
    echo "Adding terraform alias to bashrc"
    echo "alias tf='terraform'" >> $BASHRC
fi

rm -rf /tmp/tf-downloads ${GNUPGHOME}

echo "Done!"