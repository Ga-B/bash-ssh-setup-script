#!/bin/bash
trap 'stty echo; printf "\n"; exit' INT

# Configuration File Path
CONFIG_FILE="$HOME/.ssh-key-gen-config"

# Log Buffer
LOG_BUFFER=""

# Function to log messages
log() {
  local level="$1"
  local message="$2"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  local log_message="[$timestamp] [$level] $message"

  LOG_BUFFER="${LOG_BUFFER}${log_message}"$'\n'

  # echo "$message"
  if [[ "$level" == "ERROR" || "$level" == "WARNING" ]]; then
    echo "$log_message"
  fi
}

# Function to generate an SSH key
generate_ssh_key() {
  local filename="$1"
  local comment="$2"
  local passphrase="$3"

  log INFO "Generating SSH key: $filename"
  ssh-keygen -t ed25519 -C "$comment" -f "$filename" -N "$passphrase"
  if [[ $? -eq 0 ]]; then
    log INFO "SSH key generated: $filename"
  else
    log ERROR "Failed to generate SSH key: $filename"
    return 1
  fi
}

# Function to add the key to the ssh-agent
add_ssh_key() {
  local filename="$1"
  eval "$(ssh-agent -s)"
  ssh-add "$filename"
  if [[ $? -eq 0 ]]; then
    log INFO "SSH key added to ssh-agent: $filename"
  else
    log ERROR "Failed to add SSH key to ssh-agent: $filename"
    return 1
  fi
}

# Function to get user input with a prompt
get_user_input() {
  read -p "$1: " input
  echo "$input"
}

# Function to copy to clipboard (cross-platform)
copy_to_clipboard() {
  local public_key_file="$1"
  local os=$(uname -s)
  local copied="Public key copied to clipboard."

  case "$os" in
    Darwin) # macOS
      cat "$public_key_file" | pbcopy
      log INFO "$copied"
      echo "$copied"
      ;;
    Linux) # Linux
      if command -v xclip &> /dev/null; then
        cat "$public_key_file" | xclip -selection clipboard
        log INFO "$copied"
        echo "$copied"
      elif command -v xsel &> /dev/null; then
        cat "$public_key_file" | xsel -b
        log INFO "$copied"
        echo "$copied"
      else
        log WARNING "Clipboard utility not found (xclip or xsel). Key not copied to clipboard."
        return 1
      fi
      ;;
    MINGW64*|MSYS*) # Windows (Git Bash, MSYS2, etc.)
      cat "$public_key_file" | clip
      log INFO copied
      ;;
    *)
      log WARNING "Public key not copied to clipboard. Unsupported OS."
      return 1
      ;;
  esac
  return 0
}

# Function for automated remote login and key addition
add_key_remote() {
    local public_key_file="$1"
    local remote_user="$2"
    local remote_host="$3"
    local remote_path="$4"
    local remote_port="${5:-22}"  # Default to port 22

    ssh_output=$(
      ssh -p "$remote_port" "$remote_user@$remote_host" \
      "mkdir -p \"$(dirname \"$remote_path\")\" && \
      cat >> \"$remote_path\"" \
      < "$public_key_file" 2>&1
    )

    if [[ $? -eq 0 ]]; then
        log INFO "Public key added to $remote_user@$remote_host:$remote_path"
    else
        log ERROR "Error adding public key to $remote_user@$remote_host:$remote_path: $ssh_output"
        return 1
    fi
}

# Function to read config file
read_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    local config_data
    config_data=$(cat "$CONFIG_FILE")

    local line
    read -r line <<< "$config_data"

    local fields=()
    local current_field=""
    local quote_count=0  # An odd quote count means we are inside a quote

    # Manually split the line, handling quoted commas
    for ((i = 0; i < ${#line}; i++)); do
      local char="${line:$i:1}"

      if [[ "$char" == '"' ]]; then
        # Increment quote_count, then use modulo to determine if odd or even
        quote_count=$((quote_count + 1))
      elif [[ "$char" == ',' && $((quote_count % 2)) -eq 0 ]]; then
        # If a comma is encountered outside quotes, add the current_field
        fields+=("$current_field")
        current_field=""
      else
        # Append the character to the current current_field
        if [[ "$char" == " " && $((quote_count % 2)) -eq 0 ]]; then
          continue
        else
          current_field+="$char"
        fi
      fi
    done
    fields+=("$current_field") # Add the last current_field

    # Assign values from the fields array to variables
    key_name="${fields[0]}"
    comment="${fields[1]}"
    passphrase="${fields[2]}"
    remote_user="${fields[3]}"
    remote_host="${fields[4]}"
    remote_path="${fields[5]}"
    remote_port="${fields[6]}"

    log INFO "Configuration found in $CONFIG_FILE"
    echo "  - Key name: '$key_name'"
    echo "  - Comment: $(if [[ -n "$comment" ]]; then echo "'$comment'"; else echo 'None'; fi)"
    echo "  - Passphrase: $(if [[ -n "$passphrase" ]]; then echo 'Set'; else echo 'None'; fi)"
    echo "  - Remote user: '$remote_user'"
    echo "  - Remote host: '$remote_host'"
    echo "  - Remote path: '${remote_path:-"~/.ssh/authorized_keys"}'"
    echo "  - Remote port: '${remote_port:-22}'"

    read -p "Use this configuration? (y/n): " use_config
    if [[ "$use_config" == "y" ]]; then
      return 0 # Indicate success
    else
      return 1 # Indicate failure
    fi
  else
    log ERROR "Configuration file not found. Expected file: $CONFIG_FILE"
    return 1  # Indicate failure (configuration file not found)
  fi
}

# Function to get user input with password obfuscation

# Function to read a password with hidden input
#!/bin/bash

get_password_input() {
  local prompt="$1"
  local password

  # Prompt and read from /dev/tty
  printf "%s: " "$prompt" > /dev/tty
  IFS= read -rs password < /dev/tty
  printf "\n" > /dev/tty

  echo "$password"
}

get_confirmed_password() {
  local pass1 pass2

  while true; do
    pass1=$(get_password_input "Enter passphrase")
    pass2=$(get_password_input "Confirm passphrase")

    if [[ "$pass1" == "$pass2" ]]; then
      echo "$pass1"
      return 0
    else
      printf "\nPassphrases do not match. Please try again.\n\n" > /dev/tty
    fi
  done
}

# Main script
main() {
  local key_name
  local comment
  local key_path
  local passphrase
  local date_suffix
  local remote_user
  local remote_host
  local remote_path
  local remote_port

  log INFO "Script started"

  echo "*********************************"
  echo "Welcome to the SSH Key Generator!"
  echo "*********************************"
  echo ""
  echo "This script will generate an SSH key for you."
  echo "You can either use a configuration file named .ssh-key-gen-config and located in your home directory, or enter information interactively."
  echo ""

  echo "NOTE: The configuration file ~/.ssh-key-gen-config should contain the following information, separated by commas:"
  echo "key_name, comment, passphrase, remote_user, remote_host, remote_path, remote_port."
  echo "  - You can leave any parameters blank, except for the key_name. If adding a comment or passphrase with commas, enclose it in double quotes."
  echo "  - Make sure to have commas between all parameters, even if blank."
  echo ""

  read -p "Would you like to use a configuration file? (y/n): " use_config

  if [[ "$use_config" == "y" ]]; then
    if read_config; then
      log INFO "Using configuration file."
    else
      log ERROR "Failed to read configuration file. Exiting."
      echo "The configuration file should be named .ssh-key-gen-config and be located in your home directory."
      return 1 # Exit if config file read fails
    fi
  else
    log INFO "Proceeding with interactive prompts."
    echo "You will be asked for:"
    echo "  * Key name"
    echo "  * Comment (optional)"
    echo "  * Passphrase (optional)"
    echo "  * Remote user, host, path and port (optional, for remote key addition)"
    echo ""

    key_name=$(get_user_input "Enter key name (e.g., github_personal)")
    comment=$(get_user_input "Enter a comment (leave blank for no comment)")
    read -p "Would you like to enter a passphrase? (y/n): " use_passphrase
    if [[ "$use_passphrase" == "y" ]]; then
      passphrase=$(get_confirmed_password)
    else
      passphrase=""
    fi
    read -p "Would you like to enter user, host, path and port to try adding the public key to the server? (y/n)" send_to_server
    if [[ "$send_to_server" == "y" ]]; then
      remote_user=$(get_user_input "Enter remote user")
      remote_host=$(get_user_input "Enter remote host")
      remote_path=$(get_user_input "Enter remote path (leave blank to use default server path ~/.ssh/authorized_keys)")
      remote_port=$(get_user_input "Enter remote port (leave blank to use default port 22)")
    fi
  fi

  date_suffix=$(date +"_Ed25519_%m-%d-%Y_%Hh-%Mm-%Ss")
  key_path="$HOME/.ssh/${key_name}${date_suffix}"
  log INFO "The key will be saved in: $key_path"

  echo ""
  generate_ssh_key "$key_path" "$comment" "$passphrase"
  add_ssh_key "$key_path"

  echo "Public key:"
  cat "$key_path.pub"
  copy_to_clipboard "$key_path.pub"

  if [[ -n "$remote_user" && -n "$remote_host" && -n "$remote_path" ]]; then
    add_key_remote "$key_path.pub" "$remote_user" "$remote_host" "$remote_path" "$remote_port"
  fi

  # Ask the user about saving the log file
  read -p "Save log file? (y/n): " save_log
  LOG_FILE="$HOME/.ssh/logs/$key_name$date_suffix.log"

  if [[ "$save_log" == "y" ]]; then
      echo "$LOG_BUFFER" > "$LOG_FILE"
      echo "Log file saved at: $LOG_FILE"
  else
      echo "Log file not saved."
  fi

  log INFO "Script finished"
  echo ""
  echo "Your SSH key is ready. Goodbye!"
  echo ""
}

main