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
    echo -e "${Yellow}checking dependencies...${Cyan}"
    if [[ (-f $PREFIX/bin/fish) && (-f $PREFIX/bin/figlet) && (-f $PREFIX/bin/neofetch) ]]; then
        echo "${Green}all dependencies already installed."
    else
        pkg update -y
        pkg install -y fish figlet neofetch
        if type -p fish figlet neofetch &> /dev/null; then
            echo -e "${Green}dependencies installed."
        else
            echo -e "${Red}failed to install dependencies."
            echo -e $Color_Off
            exit 1
        fi
    fi
}

prerequisite

# backup and remove broken neofetch config to prevent errors
if [[ -f "$HOME/.config/neofetch/config.conf" ]]; then
    mv "$HOME/.config/neofetch/config.conf" "$HOME/.config/neofetch/config.conf.bak"
fi

# set fish greeting by overwriting fish_greeting function in config.fish
echo 'function fish_greeting
    echo "Welcome to MintOS 1.0"
end
' > "$config"

clear

echo -e $Purple
figlet -f smslant "MintOS Shell"
echo -e $Color_Off
printf '\n'
echo -e "${Blue}[*]removing termux greeting..."
sleep 2
[[ -f "$PREFIX/etc/motd" ]] && rm "$PREFIX/etc/motd"
printf '\n'
echo -e $Cyan"*removed greeting text*"
printf '\n'
sleep 2
echo -e $Green"[*]adding neofetch to mintos..." $Red
printf '\n'
sleep 2
while true; do
    read -p "show android logo on startup? (y/n): " yn
    case $yn in
        [Yy]* ) echo "neofetch" >> "$config"; break;;
        [Nn]* ) echo "neofetch --off" >> "$config"; break;;
        * ) echo "enter y or n";;
    esac
done
printf '\n'
sleep 2
echo -e $Cyan"*neofetch added*" $Green
printf '\n'
sleep 2
echo -e "[*]setting MintOS default shell..." $Blue
printf '\n'
sleep 2
chsh -s fish
echo -e "*MintOS set as default shell*"
sleep 2
printf '\n'
echo -e $Yellow"done.\n\nrestart termux.\n\n"
