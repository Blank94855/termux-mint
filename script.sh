#!/data/data/com.termux/files/usr/bin/bash
# MintOS Shell Setup Script v2

# --- Color Definitions ---
Color_Off='\033[0m'
Red='\033[0;31m'
Green='\033[1;32m'
Blue='\033[1;34m'
Yellow='\033[1;33m'
Purple='\033[0;35m'
Cyan='\033[0;36m'

# --- Global Variables ---
CONFIG_FISH_PATH="$PREFIX/etc/fish/config.fish"
NEOFETCH_CONFIG_DIR="$HOME/.config/neofetch"
NEOFETCH_CONFIG_FILE="$NEOFETCH_CONFIG_DIR/config.conf"

# --- Helper Functions ---
print_message() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${Color_Off}"
}

# --- Core Functions ---

check_dependencies() {
    print_message "$Yellow" "Checking dependencies..."
    local missing_pkgs=()
    local pkgs_to_check=("fish" "figlet" "neofetch" "lolcat")

    for pkg in "${pkgs_to_check[@]}"; do
        if ! type -p "$pkg" &>/dev/null; then
            missing_pkgs+=("$pkg")
        fi
    done

    if [[ ${#missing_pkgs[@]} -eq 0 ]]; then
        print_message "$Green" "All dependencies already installed."
    else
        print_message "$Cyan" "Installing missing dependencies: ${missing_pkgs[*]}"
        pkg update -y && pkg install -y "${missing_pkgs[@]}"
        # Verify installation
        for pkg in "${missing_pkgs[@]}"; do
            if ! type -p "$pkg" &>/dev/null; then
                print_message "$Red" "Failed to install $pkg. Please try installing it manually."
                exit 1
            fi
        done
        print_message "$Green" "Dependencies installed successfully."
    fi
}

backup_neofetch_config() {
    if [[ -f "$NEOFETCH_CONFIG_FILE" ]]; then
        local backup_file="${NEOFETCH_CONFIG_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
        print_message "$Yellow" "Backing up existing neofetch config to $backup_file..."
        mv "$NEOFETCH_CONFIG_FILE" "$backup_file"
        print_message "$Green" "Neofetch config backed up."
    fi
    # Ensure the directory exists for neofetch if it's being run for the first time
    mkdir -p "$NEOFETCH_CONFIG_DIR"
}

configure_banner_and_greeting() {
    print_message "$Purple" "--- Banner & Greeting Setup ---"

    # Get custom banner text
    read -r -p "$(echo -e "${Cyan}Enter text for your banner (default: MintOS Shell): ${Color_Off}")" banner_text
    banner_text=${banner_text:-"MintOS Shell"}

    # Choose figlet font
    local fonts=("smslant" "standard" "slant" "big" "banner" "digital" "starwars" "larry3d")
    print_message "$Cyan" "Available figlet fonts:"
    for i in "${!fonts[@]}"; do
        echo -e "${Yellow}$((i+1))) ${fonts[$i]}${Color_Off}"
    done
    local font_choice
    while true; do
        read -r -p "$(echo -e "${Cyan}Choose a font number (default: 1 for smslant): ${Color_Off}")" font_choice
        font_choice=${font_choice:-1}
        if [[ "$font_choice" =~ ^[0-9]+$ ]] && [ "$font_choice" -ge 1 ] && [ "$font_choice" -le "${#fonts[@]}" ]; then
            banner_font="${fonts[$((font_choice-1))]}"
            break
        else
            print_message "$Red" "Invalid choice. Please enter a number from the list."
        fi
    done
    print_message "$Green" "Banner text: '$banner_text', Font: '$banner_font'"

    # Create or overwrite config.fish with the new greeting
    print_message "$Yellow" "Setting up fish greeting and core aliases..."
    # Using a heredoc for cleaner multiline string
    cat > "$CONFIG_FISH_PATH" <<- EOF
# --- MintOS Fish Configuration ---

function fish_greeting
    clear
    echo ""
    figlet -f "$banner_font" "$banner_text" | lolcat -F 0.3
    echo ""
    set -l user_color (set_color blue --bold)
    set -l info_color (set_color cyan)
    set -l normal_color (set_color normal)
    set -l quote_color (set_color magenta)

    echo -e "Welcome to \033[1;35mMintOS\033[0m, \$user_color\$USER\$normal_color!"
    echo -e "--------------------------------------"
    echo -e "\$info_colorKernel:\$normal_color "(uname -o)" "(uname -r)
    echo -e "\$info_colorUptime:\$normal_color "(uptime -p | sed 's/up //')
    echo -e "\$info_colorDate:\$normal_color "(date "+%A, %B %d, %Y %I:%M %p")
    echo -e "--------------------------------------"

    # Neofetch will be added below by the script if chosen

    set -l quotes "Keep learning, stay curious!" \\
                 "Code something awesome today!" \\
                 "The only way to do great work is to love what you do." \\
                 "Persistence is key to success." \\
                 "Embrace the chaos, find the order."
    echo -e "\$quote_color\$(random choice \$quotes)\$normal_color"
    echo ""
    echo -e "Type '\033[1;32mupdateme\033[0m' to update Termux packages."
    echo -e "Type '\033[1;32mmyaliases\033[0m' to list your custom aliases."
    echo -e "Type '\033[1;32mneofetch\033[0m' to display system info."
    echo ""
end

# --- Core Aliases ---
alias updateme="pkg update -y && pkg upgrade -y && echo -e '${Green}System updated successfully!${Color_Off}'"
alias myaliases="echo -e '${Purple}--- Your Custom Aliases ---${Color_Off}'; grep -E '^alias ' '$CONFIG_FISH_PATH' | grep -vE '^alias updateme|^alias myaliases|^# User Defined Aliases Start'; echo -e '${Purple}-------------------------${Color_Off}'"

# --- User Defined Aliases Start ---
# Example: alias ll='ls -lAhF --color=auto'
EOF
    print_message "$Green" "Fish greeting and core aliases configured."
}

configure_user_aliases() {
    print_message "$Purple" "--- Custom Alias Setup ---"
    while true; do
        read -r -p "$(echo -e "${Cyan}Do you want to add a custom alias? (y/n): ${Color_Off}")" add_alias_choice
        case $add_alias_choice in
            [Yy]* )
                read -r -p "$(echo -e "${Blue}Enter alias name (e.g., ll): ${Color_Off}")" alias_name
                if [[ -z "$alias_name" ]]; then
                    print_message "$Red" "Alias name cannot be empty. Skipping."
                    continue
                fi
                read -r -p "$(echo -e "${Blue}Enter command for '$alias_name' (e.g., ls -lAhF): ${Color_Off}")" alias_command
                if [[ -z "$alias_command" ]]; then
                    print_message "$Red" "Alias command cannot be empty. Skipping."
                    continue
                fi
                # Append the alias to config.fish
                echo "alias $alias_name='$alias_command'" >> "$CONFIG_FISH_PATH"
                print_message "$Green" "Alias '$alias_name' added."
                ;;
            [Nn]* )
                print_message "$Yellow" "Skipping custom alias setup."
                break
                ;;
            * )
                print_message "$Red" "Invalid input. Please enter 'y' or 'n'."
                ;;
        esac
    done
    # Add a closing marker for clarity, though not strictly necessary for grep
    echo "# --- User Defined Aliases End ---" >> "$CONFIG_FISH_PATH"
}

finalize_setup() {
    print_message "$Purple" "--- Finalizing Setup ---"

    # Remove default Termux greeting
    print_message "$Blue" "[*] Removing default Termux greeting (motd)..."
    sleep 1
    [[ -f "$PREFIX/etc/motd" ]] && rm "$PREFIX/etc/motd"
    print_message "$Cyan" "* Default Termux greeting removed *"
    printf '\n'
    sleep 1

    # Configure Neofetch
    print_message "$Green" "[*] Adding Neofetch to MintOS..."
    sleep 1
    local neofetch_command="neofetch"
    while true; do
        read -r -p "$(echo -e "${Cyan}Show Android logo with Neofetch on startup? (y/n, default: y): ${Color_Off}")" yn_neofetch
        yn_neofetch=${yn_neofetch:-y}
        case $yn_neofetch in
            [Yy]* )
                # Default neofetch command is fine
                break
                ;;
            [Nn]* )
                neofetch_command="neofetch --off" # or your preferred neofetch config without logo
                break
                ;;
            * )
                print_message "$Red" "Invalid input. Please enter 'y' or 'n'."
                ;;
        esac
    done
    # Add neofetch command to the end of config.fish, so it runs after the greeting
    echo "" >> "$CONFIG_FISH_PATH" # Ensure it's on a new line
    echo "$neofetch_command # Display Neofetch on startup" >> "$CONFIG_FISH_PATH"
    print_message "$Cyan" "* Neofetch configured to run on startup *"
    printf '\n'
    sleep 1

    # Set Fish as default shell
    print_message "$Blue" "[*] Setting MintOS (Fish) as default shell..."
    sleep 1
    if [[ "$(basename "$SHELL")" != "fish" ]]; then
        chsh -s fish
        print_message "$Green" "* MintOS (Fish) set as default shell. *"
    else
        print_message "$Yellow" "* MintOS (Fish) is already the default shell. *"
    fi
    sleep 1
    printf '\n'
}

# --- Main Script Execution ---
clear
print_message "$Purple" "MintOS Shell Setup Initializing..."
echo -e "$Yellow===================================$Color_Off"
sleep 1

check_dependencies
backup_neofetch_config
configure_banner_and_greeting
configure_user_aliases
finalize_setup

print_message "$Green" "Setup Complete!"
print_message "$Yellow" "Please restart Termux for all changes to take effect."
echo -e "$Purple Enjoy your enhanced MintOS Shell! ✨ $Color_Off"

