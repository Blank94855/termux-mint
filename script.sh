#!/data/data/com.termux/files/usr/bin/bash
clear

Color_Off='\033[0m'
Red='\033[0;31m'
Green='\033[1;32m'
Blue='\033[1;34m'
Yellow='\033[1;33m'
Purple='\033[0;35m'
Cyan='\033[0;36m'

config="$PREFIX/etc/fish/config.fish"

clear

prerequisite() {
    { echo; echo -e "${Yellow}checking dependencies..."${Cyan}; echo; }
    if [[ (-f $PREFIX/bin/fish) && (-f $PREFIX/bin/figlet) && (-f $PREFIX/bin/neofetch) ]]; then
        { echo "${Green}all dependencies already installed."; }
    else
        { pkg update -y; pkg install -y fish figlet neofetch -y; }
        (type -p fish figlet neofetch &> /dev/null) && { echo; echo "${Green}dependencies installed."; } || { echo; echo "${Red}failed to install deps."; echo -e $Color_Off;  exit 1; }
    fi
}

prerequisite

# set fish greeting
echo 'function fish_greeting
    echo "Welcome to MintOS 1.0.0"
end

function __fish_command_not_found_handler --on-event fish_command_not_found
    /data/data/com.termux/files/usr/libexec/termux/command-not-found $argv[1]
end

function cls
    clear
end
' > "$config"

# make neofetch custom config and override shell output
mkdir -p ~/.config/neofetch
neofetch --config none > ~/.config/neofetch/config.conf

# This is the corrected part:
sed -i 's/prin("Shell")/prin("Shell", "MintOS 1.0")/g' ~/.config/neofetch/config.conf
sed -i 's/info "Shell" "\\\${shell_name}"/info "Shell" "MintOS 1.0"/g' ~/.config/neofetch/config.conf


clear

echo -e $Purple
figlet -f smslant "MintOS Shell"
echo -e $Color_Off
printf '\n'
echo -e "${Blue}[*]removing termux greeting..."
sleep 2s
[[ -f "$PREFIX/etc/motd" ]] && rm "$PREFIX/etc/motd"
printf '\n'
echo -e $Cyan"*removed greeting text*"
printf '\n'
sleep 2s
echo -e $Green"[*]adding neofetch to mintos..." $Red
printf '\n'
sleep 2s
while true; do
    read -p "show android logo on startup? (y/n): " yn
    case $yn in
        [Yy]* ) echo "neofetch --config ~/.config/neofetch/config.conf" >> "$config"; break;;
        [Nn]* ) echo "neofetch --off --config ~/.config/neofetch/config.conf" >> "$config"; break;;
        * ) echo "enter y or n";;
    esac
done
printf '\n'
sleep 2s
echo -e $Cyan"*neofetch added*" $Green
printf '\n'
sleep 2s
echo -e "[*]setting MintOS default shell..." $Blue
printf '\n'
sleep 2s
chsh -s fish
echo -e "*MintOS set as default shell*"
sleep 2s
printf '\n'
printf $Yellow"done.\n\nrestart termux.\n\n"
