#!/bin/bash

# written by: Microsoft Copilot


# Update Python package versions in ansible-requirements.txt
update_python_packages() {
    local requirements_file="ansible/ansible-requirements.txt"
    echo "Updating Python packages in $requirements_file..."
    while IFS= read -r line; do
        if [[ $line == *"=="* ]]; then
            package=$(echo "$line" | cut -d'=' -f1)
            latest_version=$(pip index versions "$package" 2>/dev/null | grep -oP '(?<=Available versions: ).*' | awk '{print $1}' | sed 's/,//')
            if [[ -n $latest_version ]]; then
                echo "Updating $package to version $latest_version"
                # Remove any trailing commas after the version
                sed -i "s|$package==.*|$package==$latest_version|" "$requirements_file"
            else
                echo "Could not fetch the latest version for $package"
            fi
        fi
    done < "$requirements_file"
}

# Update version variables in Dockerfile.ansible
update_dockerfile_versions() {
    local dockerfile="Dockerfile.ansible"
    echo "Updating version variables in $dockerfile..."

    declare -A version_sources=(
        ["PIPX_VERSION"]="pipx"
        ["ANSIBLE_VERSION"]="ansible"
        ["AZURE_CLI_VERSION"]="azure-cli"
        ["ANSIBLE_LINT_VERSION"]="ansible-lint"
    )

    for var in "${!version_sources[@]}"; do
        package="${version_sources[$var]}"
        latest_version=$(pip index versions "$package" 2>/dev/null | grep -oP '(?<=Available versions: ).*' | awk '{print $1}' | sed 's/,//')
        if [[ -n $latest_version ]]; then
            echo "Updating $var to $latest_version"
            # Ensure no trailing commas and add a backslash at the end
            sed -i "s|ARG $var=.*|ARG $var=$latest_version \\\\|" "$dockerfile"
        else
            echo "Could not fetch the latest version for $package"
        fi
    done

    # Update ANSIBLE_AZCOLLECTION_VERSION from GalaxyNG (Pulp API)
    collection="azure/azcollection"
    api_url="https://galaxy.ansible.com/api/v3/plugin/ansible/content/published/collections/index/$collection/"
    response=$(curl -s -w "%{http_code}" -o /tmp/azcollection.json "$api_url")
    http_code=$(tail -n1 <<< "$response")
    if [[ $http_code -eq 200 ]]; then
        latest_collection_version=$(jq -r '.highest_version.version' /tmp/azcollection.json)
        if [[ -n $latest_collection_version && $latest_collection_version != "null" ]]; then
            echo "Updating ANSIBLE_AZCOLLECTION_VERSION to $latest_collection_version"
            sed -i "s|ARG ANSIBLE_AZCOLLECTION_VERSION=.*|ARG ANSIBLE_AZCOLLECTION_VERSION=$latest_collection_version \\\\|" "$dockerfile"
        else
            echo "Could not parse the latest version for $collection. Please check the API response."
        fi
    else
        echo "Failed to fetch the latest version for $collection. HTTP code: $http_code"
        cat /tmp/azcollection.json
    fi
}

# Main script execution
update_python_packages
update_dockerfile_versions

echo "Update complete!"
