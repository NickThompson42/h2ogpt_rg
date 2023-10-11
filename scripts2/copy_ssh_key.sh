copy_ssh_key() {
    # Define the path to the default SSH key
    local key_path="$HOME/.ssh/id_rsa"

    # Check if the public key exists
    if [[ ! -f "${key_path}.pub" ]]; then
        # Generate a new SSH key pair
        ssh-keygen -t rsa -b 4096 -f "${key_path}" -N ""

        # Copy the public key to the clipboard
        # Using xclip for Linux. If on macOS, replace with `pbcopy`
        cat "${key_path}.pub" | xclip -selection clipboard

        # Print messages
        echo "A new key pair was created."
        echo "Your public key is copied to your clipboard, you may paste it now."
    else
        # Copy the existing public key to the clipboard
        cat "${key_path}.pub" | xclip -selection clipboard

        # Print messages
        echo "A key pair already existed."
        echo "Your public key is copied to your clipboard, you may paste it now."
    fi
}
