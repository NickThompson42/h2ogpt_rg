copy_ssh_key() {
    # Define the path to the default SSH key
    local key_path="$HOME/.ssh/id_rsa"

    # Check if the public key exists
    if [[ ! -f "${key_path}.pub" ]]; then
        # Generate a new SSH key pair
        ssh-keygen -t rsa -b 4096 -f "${key_path}" -N ""

        # Print messages
        echo "A new key pair was created."
    else
        # Print messages
        echo "A key pair already existed."
    fi

    # Print the public key to the console
    echo "Your public key is:"
    cat "${key_path}.pub"
}
