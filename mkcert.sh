#!/usr/bin/env bash

# mkcert certificate generation script with robust domain loading

set -e  # Exit on any error

# Help function
show_help() {
    cat << EOF
mkcert Certificate Generator

DESCRIPTION:
    Generate SSL certificates using mkcert with robust domain loading from files.
    Automatically cleans up existing certificates and reinstalls CA certificates.

USAGE:
    ./mkcert.sh [OPTIONS]

OPTIONS:
    -h, --help            Show this help message and exit
    -f, --force           Skip confirmation prompts (useful for automation)
    --cert-file FILE      Certificate output file (default: cert.pem)
    --key-file FILE       Private key output file (default: key.pem)
    --domains CSV         Comma-separated list of domains
    --file FILE           Domains file to read from (default: .domains)

DOMAIN CONFIGURATION:
    Domains can be specified in three ways (in order of preference):
    1. Command line: --domains "example.com,localhost,127.0.0.1"
    2. .domains file: One domain per line, comments with #
    3. Default: *.localhost localhost 127.0.0.1 ::1

EXAMPLES:
    # Generate with defaults
    ./mkcert.sh

    # Custom certificate filenames
    ./mkcert.sh --cert-file wildcard.crt --key-file wildcard.key

    # Force mode (no prompts)
    ./mkcert.sh --force

    # For Traefik setup
    ./mkcert.sh --cert-file _wildcard.localhost+3.pem --key-file _wildcard.localhost+3-key.pem

    # Custom domains via command line
    ./mkcert.sh --domains "api.localhost,web.localhost,127.0.0.1"

    # Custom domains file
    ./mkcert.sh --file my-domains.txt

FILES:
    .domains              Optional file with one domain per line
    cert.pem              Default certificate output file
    key.pem               Default private key output file

NOTES:
    - Existing certificate files will be removed before generation
    - CA certificate is reinstalled for clean trust store setup
    - Browser restart may be required for certificates to take effect

EOF
}

# Parse command line arguments
FORCE=false
CERT_FILE="cert.pem"
KEY_FILE="key.pem"
DOMAINS=""
DOMAINS_FILE=".domains"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --cert-file)
            CERT_FILE="$2"
            shift 2
            ;;
        --key-file)
            KEY_FILE="$2"
            shift 2
            ;;
        --domains)
            DOMAINS="$2"
            shift 2
            ;;
        --file)
            DOMAINS_FILE="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

echo "=== mkcert Certificate Generator ==="

# Find the cert root path
CAROOT=$(mkcert -CAROOT)
echo "Certificate ROOT: $CAROOT"
echo

set_domains_from_file() {
    local file="$1"

    # Check conditions
    if [ -n "$DOMAINS" ]; then
        echo "DOMAINS already set: $DOMAINS"
        return 0
    fi

    if [ ! -f "$file" ]; then
        echo "Warning: $file not found, using defaults"
        return 1
    fi

    echo "Reading domains from $file..."

    # Read and process domains
    local domains=()
    while IFS= read -r line; do
        # Remove leading/trailing whitespace
        line=$(echo "$line" | xargs)

        # Skip empty lines and comments
        if [[ -n "$line" && ! "$line" =~ ^# ]]; then
            domains+=("$line")
        fi
    done < "$file"

    if [ ${#domains[@]} -eq 0 ]; then
        echo "Warning: No valid domains found in $file"
        return 1
    fi

    # Convert array to space-separated string
    DOMAINS="${domains[*]}"
    echo "DOMAINS set from $file: $DOMAINS"
    export DOMAINS
    return 0
}

# Process domains from CSV if provided
if [ -n "$DOMAINS" ]; then
    # Split CSV and clean up domains
    DOMAINS=$(echo "$DOMAINS" | tr ',' ' ' | xargs)
elif [ -f "$DOMAINS_FILE" ]; then
    set_domains_from_file "$DOMAINS_FILE"
fi

# Fallback to default domains if still not set
if [ -z "$DOMAINS" ]; then
    DOMAINS="*.localhost localhost 127.0.0.1 ::1"
    echo "Using default domains: $DOMAINS"
fi

echo
echo "=== Cleaning up existing certificates ==="
# Check if any certificate files exist
if ls *.pem 2>/dev/null || ls *localhost*.pem 2>/dev/null || ls _wildcard.* 2>/dev/null; then
    echo "Found existing certificate files:"
    ls -la *.pem *localhost*.pem _wildcard.* 2>/dev/null || true
    echo

    if [ "$FORCE" = true ]; then
        echo "Force mode: Removing existing certificates without confirmation"
        REPLY="y"
    else
        read -p "Do you want to remove existing certificates? (y/N): " -n 1 -r
        echo
    fi

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Remove any existing certificate files with common patterns
        rm -f *.pem
        rm -f *localhost*.pem
        rm -f cert.pem key.pem
        rm -f _wildcard.*
        echo "Removed existing certificate files"
    else
        echo "Keeping existing certificates. Note: This may cause conflicts."
    fi
else
    echo "No existing certificate files found"
fi

echo
echo "=== Generating certificates ==="
echo "Domains: $DOMAINS"
echo "Certificate file: $CERT_FILE"
echo "Key file: $KEY_FILE"

# Generate the cert keys
mkcert --cert-file "$CERT_FILE" --key-file "$KEY_FILE" $DOMAINS

echo
echo "=== Reinstalling root certificate ==="
# Uninstall existing CA certificate first
echo "Uninstalling existing CA certificate..."
mkcert -uninstall

# Install the root cert in system and browser trust stores
echo "Installing fresh CA certificate..."
mkcert -install

echo
echo "=== Certificate generation complete! ==="
echo "Certificate: $CERT_FILE"
echo "Private key: $KEY_FILE"
echo "CA Root: $CAROOT"
echo
echo "You may need to restart your browser for the certificates to take effect."
echo
