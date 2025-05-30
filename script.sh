#!/data/data/com.termux/files/usr/bin/bash

Color_Off='\033[0m'
Red='\033[0;31m'
Green='\033[1;32m'
Blue='\033[1;34m'
Yellow='\033[1;33m'
Purple='\033[0;35m'
Cyan='\033[0;36m'

CONFIG_FISH_PATH="$PREFIX/etc/fish/config.fish"
NEOFETCH_CONFIG_DIR="$HOME/.config/neofetch"
NEOFETCH_CONFIG_FILE="$NEOFETCH_CONFIG_DIR/config.conf"
SCRIPT_VERSION="1.1"

print_message() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${Color_Off}"
}

command_exists() {
    type -p "$1" &>/dev/null
}

check_dependencies() {
    print_message "$Yellow" "Updating package lists. This might take a moment..."
    if ! pkg update -y; then
        print_message "$Red" "Failed to update package lists (pkg update -y)."
        print_message "$Red" "Please check your internet connection and Termux repositories."
        print_message "$Red" "You might need to run 'termux-change-repo' and select different mirrors, then try the script again."
        exit 1
    fi
    print_message "$Green" "Package lists updated successfully."

    print_message "$Yellow" "Checking dependencies..."
    local missing_pkgs_to_install=()
    local pkgs_to_check=("fish" "figlet" "neofetch" "lolcat")
    local essential_pkgs=("fish" "figlet" "neofetch")

    for pkg in "${pkgs_to_check[@]}"; do
        if ! command_exists "$pkg"; then
            missing_pkgs_to_install+=("$pkg")
        fi
    done

    if [[ ${#missing_pkgs_to_install[@]} -eq 0 ]]; then
        print_message "$Green" "All dependencies already installed."
    else
        print_message "$Cyan" "Attempting to install missing/optional dependencies: ${missing_pkgs_to_install[*]}"
        if ! pkg install -y "${missing_pkgs_to_install[@]}"; then
            print_message "$Yellow" "The package installation command (pkg install -y ...) reported an issue."
            print_message "$Yellow" "Proceeding to verify essential packages..."
        else
            print_message "$Green" "Package installation command completed successfully."
        fi
        
        local essential_pkg_failed=false
        for pkg in "${essential_pkgs[@]}"; do
            if ! command_exists "$pkg"; then
                print_message "$Red" "Failed to install or verify essential dependency: $pkg."
                essential_pkg_failed=true
            fi
        done

        if $essential_pkg_failed; then
            print_message "$Red" "One or more essential dependencies could not be installed."
            print_message "$Red" "Please try installing them manually (e.g., 'pkg install fish') after ensuring 'pkg update' was successful."
            print_message "$Red" "Script cannot continue."
            exit 1
        fi

        if command_exists "lolcat"; then
            print_message "$Green" "All essential dependencies installed. Optional 'lolcat' is also available."
        else
            print_message "$Yellow" "All essential dependencies installed. Optional 'lolcat' could not be installed/found. Banner will not be rainbow colored."
        fi
    fi
}

backup_neofetch_config() {
    if [[ -f "$NEOFETCH_CONFIG_FILE" ]]; then
        local backup_file="${NEOFETCH_CONFIG_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
        print_message "$Yellow" "Backing up existing neofetch config to $backup_file..."
        mv "$NEOFETCH_CONFIG_FILE" "$backup_file"
        print_message "$Green" "Neofetch config backed up."
    fi
    mkdir -p "$NEOFETCH_CONFIG_DIR"
}

configure_banner_and_greeting() {
    print_message "$Purple" "--- Banner & Greeting Setup (v$SCRIPT_VERSION) ---"

    read -r -p "$(echo -e "${Cyan}Enter text for your banner (default: MintOS Shell): ${Color_Off}")" banner_text
    banner_text=${banner_text:-"MintOS Shell"}

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

    local banner_command
    if command_exists "lolcat"; then
        banner_command="figlet -f \"$banner_font\" \"$banner_text\" | lolcat -F 0.3"
        print_message "$Cyan" "lolcat found! Banner will be colorful. ✨"
    else
        banner_command="figlet -f \"$banner_font\" \"$banner_text\""
        print_message "$Yellow" "lolcat not found. Banner will be standard color."
    fi

    print_message "$Yellow" "Setting up fish greeting and core aliases..."
    cat > "$CONFIG_FISH_PATH" <<- EOF
# --- MintOS Fish Configuration v$SCRIPT_VERSION ---

function fish_greeting
    clear
    echo ""
    $banner_command
    echo ""
    set -l user_color (set_color blue --bold)
    set -l info_color (set_color cyan)
    set -l normal_color (set_color normal)
    set -l quote_color (set_color magenta)
    set -l version_color (set_color --bold white)

    echo -e "Welcome to \033[1;35mMintOS\033[0m \$version_color(v$SCRIPT_VERSION)\$normal_color, \$user_color\$USER\$normal_color!"
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
alias myaliases="echo -e '${Purple}--- Your Custom Aliases (v$SCRIPT_VERSION) ---${Color_Off}'; grep -E '^alias ' '$CONFIG_FISH_PATH' | grep -vE '^alias updateme|^alias myaliases|^# User Defined Aliases Start'; echo -e '${Purple}-------------------------${Color_Off}'"

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
    echo "# --- User Defined Aliases End ---" >> "$CONFIG_FISH_PATH"
}

finalize_setup() {
    print_message "$Purple" "--- Finalizing Setup ---"

    print_message "$Blue" "[*] Removing default Termux greeting (motd)..."
    sleep 1
    [[ -f "$PREFIX/etc/motd" ]] && rm "$PREFIX/etc/motd"
    print_message "$Cyan" "* Default Termux greeting removed *"
    printf '\n'
    sleep 1

    print_message "$Green" "[*] Adding Neofetch to MintOS..."
    sleep 1
    local neofetch_command="neofetch"
    while true; do
        read -r -p "$(echo -e "${Cyan}Show Android logo with Neofetch on startup? (y/n, default: y): ${Color_Off}")" yn_neofetch
        yn_neofetch=${yn_neofetch:-y}
        case $yn_neofetch in
            [Yy]* )
                break
                ;;
            [Nn]* )
                neofetch_command="neofetch --off"
                break
                ;;
            * )
                print_message "$Red" "Invalid input. Please enter 'y' or 'n'."
                ;;
        esac
    done
    echo "" >> "$CONFIG_FISH_PATH"
    echo "$neofetch_command # Display Neofetch on startup" >> "$CONFIG_FISH_PATH"
    print_message "$Cyan" "* Neofetch configured to run on startup *"
    printf '\n'
    sleep 1

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

clear
print_message "$Purple" "MintOS Shell Setup v$SCRIPT_VERSION Initializing..."
echo -e "$Yellow===================================$Color_Off"
sleep 1

check_dependencies
backup_neofetch_config
configure_banner_and_greeting
configure_user_aliases
finalize_setup

print_message "$Green" "Setup Complete!"
print_message "$Yellow" "Please restart Termux for all changes to take effect."
echo -e "$Purple Enjoy your enhanced MintOS Shell v$SCRIPT_VERSION! ✨ $Color_Off"


 
