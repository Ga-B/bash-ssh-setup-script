**README.md**

# SSH Key Generator

This Bash script automates the creation and initial management of SSH keys on macOS and Linux. It generates secure Ed25519 keys, adds them to the `ssh-agent`, copies the public key to the clipboard, and optionally sends the public key to a remote server.

## Features

* **Configuration File Support:** Reads settings from a configuration file (`~/.ssh-key-gen-config`) located in the user's home directory to streamline key generation.
* **Interactive Prompts:** If no configuration file is found, or if the user chooses to enter data interactively, the script prompts for necessary information.
* **Automated Remote Key Addition:** Automatically adds the public key to a remote server's `authorized_keys` file via SSH.
* **Clipboard Copy:** Copies the public key to the clipboard (cross-platform support for macOS and Linux).
* **Date/Time Suffix:** Appends a date/time suffix to key filenames to prevent overwriting.
* **Ed25519 Keys:** Generates secure Ed25519 keys.
* **Passphrase Support:** Allows setting a passphrase for the SSH key.
* **Detailed Error Messages:** Provides informative error messages, especially for remote key addition.
* **Logging:** Log messages are displayed in the terminal. Before exiting the script, users  can choose to save the log to their home folder, or discard it altogether.

## Prerequisites

* macOS or Linux.
* Bash or Zsh shell.
* Optional: either `xclip` or `xsel` for clipboard copy in Linux.
* Fields cannot contain double quotes.

## Usage

1.  **Save the script:** Save the script as a `.sh` file (e.g., `ssh-key-gen.sh`).
2.  **Make it executable:** `chmod +x ssh-key-gen.sh`
3.  **Run the script:** Copy the path to the script, e.g. /path/to/ssh-key-gen.sh. Run `bash /path/to/ssh-key-gen.sh`. The script will prompt you for details.

## Configuration File

The script can read settings from a configuration file `~/.ssh-key-gen-config` in the user's home directory. The file should contain the following values, separated by commas (all but `key_name` can be left blank).

```
key_name, comment, passphrase, remote_user, remote_host, remote_path, remote_port,
```

* `key_name`: The name of the key (e.g., `github_personal`).
* `comment`: The comment for the key (e.g., `your_email@example.com`). Can be left blank; if it includes its own commas, the comment must be enclosed in double quotes.
* `passphrase`: The passphrase for the key (leave blank for no passphrase). If you want a passphrase with commas, it must be enclosed in double quotes.
* `remote_user`: The remote username (optional).
* `remote_host`: The remote hostname or IP address (optional).
* `remote_path`: The remote path to the `authorized_keys` file (optional, defaults to `~/.ssh/authorized_keys`).
* `remote_port`: The remote SSH port (optional, defaults to 22).

**Example Configuration File Contents:**

```
some_name, "My comment, with a comma.", the_password, the_user, server.example.com, ~/.ssh/authorized_keys, 2222
```

```
some_name, , , the_user, , , 
```

## Example Script Runs

**Using Configuration File:**

```
*********************************
Welcome to the SSH Key Generator!
*********************************

This script will generate an SSH key for you.
You can either use a configuration file named .ssh-key-gen-config and located in your home directory, or enter information interactively.

NOTE: The configuration file ~/.ssh-key-gen-config should contain the following information, separated by commas:
key_name, comment, passphrase, remote_user, remote_host, remote_path, remote_port.
  - You can leave any parameters empty, except for the key_name. If adding a comment or passphrase with commas, enclose it in double quotes.
  - Make sure to have commas between all parameters, even if empty. 

Would you like to use a configuration file? (y/n): y
  Key name: 'some_name'
  Comment: 'My comment, with a comma'
  Passphrase: Set
  Remote user: 'the_user'
  Remote host: 'server.example.com'
  Remote path: '~/.ssh/authorized_keys'
  Remote port: '2222'
Use this configuration? (y/n): y

Generating public/private ed25519 key pair.
Your identification has been saved in /Users/youruser/.ssh/some_name_Ed25519_05-26-2024_10h-30m-00s
Your public key has been saved in /Users/youruser/.ssh/some_name_Ed25519_05-26-2024_10h-30m-00s.pub
The key fingerprint is:
SHA256:3hjdQcQKJD8uudroq6rMOKEFIxzLW6RUcRDwiFwocjs My comment, with a comma.
The key's randomart image is:
+--[ED25519 256]--+
| .+*+....  oo    |
|=+=..  o.  ..    |
|B+=o    o. ..    |
|+=E.   + +.. .   |
|.oo.  o S . .    |
|...    + +       |
|.o    . o .      |
|*    +           |
|==.o=..          |
+----[SHA256]-----+
Agent pid 38190
Enter passphrase for ~/.ssh/some_name__Ed25519_05-26-2024_10h-30m-00s:
Public key:
ssh-ed25519 AAA... youruser@yourhost
Public key copied to clipboard.
Public key added to user@server.example.com:~/.ssh/authorized_keys
Save log file? (y/n): y
Log file saved at: /Users/youruser/.ssh/ssh-key-gen.log

Your SSH key is ready. Goodbye!
```

**Using User Input Parameters:**

```
*********************************
Welcome to the SSH Key Generator!
*********************************

This script will generate an SSH key for you.
You can either use a configuration file at /Users/youruser/.ssh-key-gen-config or enter the information interactively.

Would you like to use the configuration file? (y/n): n
Proceeding with interactive prompts.
You will be asked for:

  * Key name
  * Comment (optional)
  * Passphrase (optional)
  * Remote user, host, path and port (optional, for remote key addition)

Enter key name (e.g., github_personal): my_new_key
Enter a comment (leave blank for no comment): This is a comment.
Enter passphrase (leave blank for no passphrase):
Would you like to enter user, host, path and port to try adding the public key to the server? (y/n) n

Generating public/private ed25519 key pair.
Your identification has been saved in ~/.ssh/my_new_key__Ed25519_05-26-2024_10h-30m-00s
Your public key has been saved in ~/.ssh/my_new_key__Ed25519_05-26-2024_10h-30m-00s.pub
The key fingerprint is:
SHA256:NTVQDv2gS765VfSZ3Kw5w3PKHBHdmhPVboV06nJKPbA This is a comment.
The key's randomart image is:
+--[ED25519 256]--+
|          o+=o.++|
|           +ooooo|
|          o.+oo=.|
|         .oo B*o*|
|        So .E B*+|
|          o+ % o |
|           o* o  |
|          o.   . |
|          ..     |
+----[SHA256]-----+
Agent pid 41410
Enter passphrase for ~/.ssh/my_new_key__Ed25519_05-26-2024_10h-30m-00s:
Identity added: ~/.ssh/my_new_key__Ed25519_05-26-2024_10h-30m-00s (This is a comment.)
Public key:
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AbAAIECA3biIRMcLmg5Ptzxyj9F1B+QsqTz7L2h5yk1+fRjv This is a comment.
Save log file? (y/n): n
Log file not saved.

Your SSH key is ready. Goodbye!.
```

## Notes

* Ensure that the remote server's `authorized_keys` file has the correct permissions.
* If the configuration file is chosen, and the file does not exist, or an error occurs while reading it, the script will exit.
* The remote path argument is a path on the remote server, and is independent of the client operating system.
* If the remote path argument is not provided, the default path `~/.ssh/authorized_keys` will be used on the remote server.
* If the remote port argument is not provided, the default port `22` will be used.