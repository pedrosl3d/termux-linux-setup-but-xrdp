#!/data/data/com.termux/files/usr/bin/bash
#######################################################
#  Termux Linux Setup Script
#  
#  Features:
#  - Choice of Desktop Environment (XFCE, LXQt, MATE, KDE)
#  - Smart GPU acceleration detection (Turnip/Zink)
#  - Productivity and Media tools (VLC, Firefox)
#  - Python & Web Dev environment pre-installed
#  - Windows App Support (Wine/Hangover)
#  - XRDP Remote Desktop: connect from Windows' native
#    Remote Desktop Connection (mstsc), no extra APK needed
#######################################################

# ============== CONFIGURATION ==============
TOTAL_STEPS=12
RDP_PORT=3389
CURRENT_STEP=0
DE_CHOICE="1"
DE_NAME="XFCE4"

# ============== COLORS ==============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'

# ============== PROGRESS FUNCTIONS ==============
update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    
    FILLED=$((PERCENT / 5))
    EMPTY=$((20 - FILLED))
    
    BAR="${GREEN}"
    for ((i=0; i<FILLED; i++)); do BAR+="*"; done
    BAR+="${GRAY}"
    for ((i=0; i<EMPTY; i++)); do BAR+="-"; done
    BAR+="${NC}"
    
    echo ""
    echo -e "${WHITE}------------------------------------------------------------${NC}"
    echo -e "${CYAN}  OVERALL PROGRESS: ${WHITE}Step ${CURRENT_STEP}/${TOTAL_STEPS}${NC} ${BAR} ${WHITE}${PERCENT}%${NC}"
    echo -e "${WHITE}------------------------------------------------------------${NC}"
    echo ""
}

spinner() {
    local pid=$1
    local message=$2
    local spin='-\|/'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "\r  [*] ${message} ${CYAN}${spin:$i:1}${NC}  "
        sleep 0.1
    done
    
    wait $pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        printf "\r  [+] ${message}                    \n"
    else
        printf "\r  [-] ${message} ${RED}(failed)${NC}     \n"
    fi
    
    return $exit_code
}

install_pkg() {
    local pkg=$1
    local name=${2:-$pkg}
    (DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::="--force-confold" $pkg > /dev/null 2>&1) &
    spinner $! "Installing ${name}..."
}

# ============== BANNER ==============
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'BANNER'
    -------------------------------------------
                                               
            Termux Linux Setup Script          
                                               
    -------------------------------------------
BANNER
    echo -e "${NC}"
    echo ""
}

# ============== DEVICE & USER SELECTION ==============
setup_environment() {
    echo -e "${PURPLE}[*] Detecting your device...${NC}"
    echo ""
    
    DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
    DEVICE_BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
    ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    CPU_ABI=$(getprop ro.product.cpu.abi 2>/dev/null || echo "arm64-v8a")
    GPU_VENDOR=$(getprop ro.hardware.egl 2>/dev/null || echo "")
    
    echo -e "  [*] Device: ${WHITE}${DEVICE_BRAND} ${DEVICE_MODEL}${NC}"
    echo -e "  [*] Android: ${WHITE}${ANDROID_VERSION}${NC}"
    
    if [[ "$GPU_VENDOR" == *"adreno"* ]] || [[ "$DEVICE_BRAND" == *"samsung"* ]] || [[ "$DEVICE_BRAND" == *"Samsung"* ]] || [[ "$DEVICE_BRAND" == *"oneplus"* ]] || [[ "$DEVICE_BRAND" == *"xiaomi"* ]]; then
        GPU_DRIVER="freedreno"
        echo -e "  [*] GPU: ${WHITE}Adreno (Qualcomm) - Hardware Acceleration Supported${NC}"
    else
        GPU_DRIVER="zink_native"
        echo -e "  [*] GPU: ${WHITE}Non-Adreno - Zink Native Vulkan${NC}"
        echo -e "${YELLOW}      [!] WARNING: Your device may not fully support advanced GPU acceleration.${NC}"
        echo -e "${YELLOW}      [!] We HIGHLY RECOMMEND choosing LXQt or XFCE for smooth performance.${NC}"
    fi
    echo ""
    
    echo -e "${CYAN}Please choose your Desktop Environment:${NC}"
    echo -e "  ${WHITE}1) XFCE4${NC}       (Recommended - Fast, Customizable, macOS style dock)"
    echo -e "  ${WHITE}2) LXQt${NC}        (Ultra lightweight - Best for low end devices)"
    echo -e "  ${WHITE}3) MATE${NC}        (Classic UI, moderately heavy)"
    echo -e "  ${WHITE}4) KDE Plasma${NC}  (Very heavy - Modern, Windows 11 style, requires strong GPU/RAM)"
    echo ""
    while true; do
        read -p "Enter number (1-4) [default: 1]: " DE_INPUT
        DE_INPUT=${DE_INPUT:-1}
        if [[ "$DE_INPUT" =~ ^[1-4]$ ]]; then
            DE_CHOICE="$DE_INPUT"
            break
        else
            echo "Invalid input. Please enter 1, 2, 3, or 4."
        fi
    done
    
    case $DE_CHOICE in
        1) DE_NAME="XFCE4";;
        2) DE_NAME="LXQt";;
        3) DE_NAME="MATE";;
        4) DE_NAME="KDE Plasma";;
    esac
    
    echo -e "\n${GREEN}[+] Selected: ${DE_NAME}.${NC}"
    sleep 2
}

# ============== STEP 1: UPDATE SYSTEM ==============
step_update() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Updating system packages...${NC}"
    echo ""
    (DEBIAN_FRONTEND=noninteractive apt-get update -y > /dev/null 2>&1) &
    spinner $! "Updating package lists..."
    (DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -q -o Dpkg::Options::="--force-confold" > /dev/null 2>&1) &
    spinner $! "Upgrading installed packages..."
}

# ============== STEP 2: INSTALL REPOSITORIES ==============
step_repos() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Adding package repositories...${NC}"
    echo ""
    install_pkg "x11-repo" "X11 Repository"
    install_pkg "tur-repo" "TUR Repository (Firefox)"
}

# ============== STEP 3: INSTALL XRDP (REMOTE DESKTOP) ==============
step_xrdp() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing XRDP (Remote Desktop Server)...${NC}"
    echo ""
    install_pkg "xrdp" "XRDP Server"
    install_pkg "xorg-xrandr" "XRandR (Display Settings)"
    install_pkg "iproute2" "Network Tools (IP detection)"
    install_pkg "passwd" "Login Password Utility"

    # Make sure xrdp listens on all network interfaces (so the PC on the
    # same Wi-Fi can reach it), not just localhost.
    XRDP_INI="$PREFIX/etc/xrdp/xrdp.ini"
    if [ -f "$XRDP_INI" ]; then
        sed -i "s/^address=.*/address=0.0.0.0/" "$XRDP_INI" 2>/dev/null
        sed -i "s/^port=.*/port=${RDP_PORT}/" "$XRDP_INI" 2>/dev/null
    fi

    echo ""
    echo -e "${YELLOW}[!] O XRDP autentica a conexao com uma senha Unix do seu usuario Termux.${NC}"
    echo -e "${YELLOW}[!] Defina agora uma senha para '$(whoami)' (sera pedida ao conectar pelo PC):${NC}"
    echo ""
    passwd
}


# ============== STEP 4: INSTALL DESKTOP ==============
step_desktop() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing ${DE_NAME} Desktop...${NC}"
    echo ""
    
    if [ "$DE_CHOICE" == "1" ]; then
        # XFCE
        install_pkg "xfce4" "XFCE4 Desktop"
        install_pkg "xfce4-terminal" "XFCE4 Terminal"
        install_pkg "xfce4-whiskermenu-plugin" "Whisker Menu"
        install_pkg "plank-reloaded" "Plank Dock"
        install_pkg "thunar" "Thunar File Manager"
        install_pkg "mousepad" "Mousepad Editor"
    elif [ "$DE_CHOICE" == "2" ]; then
        # LXQt
        install_pkg "lxqt" "LXQt Desktop"
        install_pkg "qterminal" "QTerminal"
        install_pkg "pcmanfm-qt" "PCManFM-Qt"
        install_pkg "featherpad" "FeatherPad"
    elif [ "$DE_CHOICE" == "3" ]; then
        # MATE
        install_pkg "mate" "MATE Desktop"
        install_pkg "mate-tweak" "MATE Tweak"
        install_pkg "plank-reloaded" "Plank Dock"
        install_pkg "mate-terminal" "MATE Terminal"
    elif [ "$DE_CHOICE" == "4" ]; then
        # KDE
        install_pkg "plasma-desktop" "KDE Plasma"
        install_pkg "konsole" "Konsole"
        install_pkg "dolphin" "Dolphin"
    fi
}

# ============== STEP 5: INSTALL GPU DRIVERS ==============
step_gpu() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing GPU Acceleration...${NC}"
    echo ""
    install_pkg "mesa-zink" "Mesa Zink Core"
    if [ "$GPU_DRIVER" == "freedreno" ]; then
        install_pkg "mesa-vulkan-icd-freedreno" "Turnip Adreno Driver"
    fi
    install_pkg "vulkan-loader-android" "Vulkan Loader"
}

# ============== STEP 6: INSTALL AUDIO ==============
step_audio() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Audio...${NC}"
    echo ""
    install_pkg "pulseaudio" "PulseAudio Server"
}

# ============== STEP 7: INSTALL APPS (VS Code, VLC, etc.) ==============
step_apps() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Media & Dev Apps...${NC}"
    echo ""
    install_pkg "firefox" "Firefox Browser"
    install_pkg "vlc" "VLC Media Player"
    install_pkg "git" "Git Version Control"
    install_pkg "wget" "Wget Downloader"
    install_pkg "curl" "cURL"
}

# ============== STEP 8: PYTHON & FLASK DEMO ==============
step_python() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Python Environment...${NC}"
    echo ""
    install_pkg "python" "Python 3"
    
    (pip install flask > /dev/null 2>&1) &
    spinner $! "Installing Flask Web Framework..."
    
    # Create Python Demo
    mkdir -p ~/demo_python
    cat > ~/demo_python/app.py << 'EOF'
from flask import Flask, render_template_string
app = Flask(__name__)

@app.route("/")
def hello():
    return render_template_string("""
    <html>
        <body style="background-color:#1e1e1e;color:#00ff00;font-family:monospace;text-align:center;padding:50px">
            <h1>Hardware Accelerated Linux</h1>
            <h3>This Python server is running natively on a Snapdragon Android phone!</h3>
        </body>
    </html>
    """)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF
    echo -e "  [+] Python Web Demo created in ~/demo_python"
}

# ============== STEP 9: INSTALL WINE ==============
step_wine() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Windows Support (Wine/Box64)...${NC}"
    echo ""
    (pkg remove wine-stable -y > /dev/null 2>&1) &
    spinner $! "Removing old Wine versions..."
    
    install_pkg "hangover-wine" "Wine Compatibility Layer"
    install_pkg "hangover-wowbox64" "Box64 Wrapper"
    
    ln -sf /data/data/com.termux/files/usr/opt/hangover-wine/bin/wine /data/data/com.termux/files/usr/bin/wine
    ln -sf /data/data/com.termux/files/usr/opt/hangover-wine/bin/winecfg /data/data/com.termux/files/usr/bin/winecfg
}

# ============== STEP 10: CREATE LAUNCHERS ==============
step_launchers() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Configuring Startup Scripts...${NC}"
    echo ""
    
    mkdir -p ~/.config
    
    # Base XDG variables for Termux Paths
    XDG_INJECT="export XDG_DATA_DIRS=/data/data/com.termux/files/usr/share:\${XDG_DATA_DIRS}\nexport XDG_CONFIG_DIRS=/data/data/com.termux/files/usr/etc/xdg:\${XDG_CONFIG_DIRS}"

    # KDE needs a special env injection
    if [ "$DE_CHOICE" == "4" ]; then
        mkdir -p ~/.config/plasma-workspace/env
        echo -e "#!/data/data/com.termux/files/usr/bin/bash\n$XDG_INJECT" > ~/.config/plasma-workspace/env/xdg_fix.sh
        chmod +x ~/.config/plasma-workspace/env/xdg_fix.sh
    fi
    
    # GPU & Environment Config
    cat > ~/.config/linux-gpu.sh << EOF
export MESA_NO_ERROR=1
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLES_VERSION_OVERRIDE=3.2
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform
export MESA_VK_WSI_PRESENT_MODE=immediate
export ZINK_DESCRIPTORS=lazy
EOF

    if [ "$DE_CHOICE" == "4" ]; then
        echo "export KWIN_COMPOSE=O2ES" >> ~/.config/linux-gpu.sh
    else
        echo -e "$XDG_INJECT" >> ~/.config/linux-gpu.sh
    fi
    
    # Create Plank autostart if XFCE or MATE
    if [ "$DE_CHOICE" == "1" ] || [ "$DE_CHOICE" == "3" ]; then
        mkdir -p ~/.config/autostart
        cat > ~/.config/autostart/plank.desktop << 'PLANKEOF'
[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank
PLANKEOF
    else
        rm -f ~/.config/autostart/plank.desktop 2>/dev/null
    fi

    # Determine session/kill commands based on DE
    case $DE_CHOICE in
        1)
            SESSION_CMD="startxfce4"
            KILL_CMD="pkill -9 xfce4-session; pkill -9 plank"
            ;;
        2)
            SESSION_CMD="startlxqt"
            KILL_CMD="pkill -9 lxqt-session"
            ;;
        3)
            SESSION_CMD="mate-session"
            KILL_CMD="pkill -9 mate-session; pkill -9 plank"
            ;;
        4)
            SESSION_CMD="startplasma-x11"
            KILL_CMD="pkill -9 startplasma-x11; pkill -9 kwin_x11"
            ;;
    esac

    # ~/.xsession is what xrdp-sesman runs when a Windows client logs in.
    # This replaces "launching the DE directly" from the old termux-x11 flow.
    cat > ~/.xsession << SESSIONEOF
#!/data/data/com.termux/files/usr/bin/bash
source ~/.config/linux-gpu.sh 2>/dev/null
exec ${SESSION_CMD}
SESSIONEOF
    chmod +x ~/.xsession
    echo -e "  [+] Created ~/.xsession (${DE_NAME} session for XRDP)"

    # Main Launcher: starts the xrdp daemons + audio. The actual desktop
    # is started automatically by xrdp-sesman via ~/.xsession once you
    # connect from the Windows Remote Desktop client.
    cat > ~/start-xrdp.sh << LAUNCHEREOF
#!/data/data/com.termux/files/usr/bin/bash
echo ""
echo "[*] Starting XRDP (${DE_NAME})..."
echo ""

echo "[*] Cleaning up old sessions..."
pkill -9 -f "xrdp-sesman" 2>/dev/null
pkill -9 -f "xrdp" 2>/dev/null
${KILL_CMD} 2>/dev/null
pkill -9 -f "dbus" 2>/dev/null

unset PULSE_SERVER
pulseaudio --kill 2>/dev/null
sleep 0.5
echo "[*] Starting audio server..."
pulseaudio --start --exit-idle-time=-1
sleep 1
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null
export PULSE_SERVER=127.0.0.1

echo "[*] Starting XRDP services..."
xrdp-sesman > ~/.xrdp-sesman.log 2>&1 &
sleep 1
xrdp --nodaemon > ~/.xrdp.log 2>&1 &
sleep 2

bash ~/rdp-info.sh

echo "[*] XRDP esta rodando. Mantenha o Termux aberto enquanto usar a area de trabalho."
echo "[*] Para parar: ./stop-xrdp.sh"
echo ""
wait
LAUNCHEREOF
    chmod +x ~/start-xrdp.sh
    echo -e "  [+] Created ~/start-xrdp.sh"
    
    # Stopper
    cat > ~/stop-xrdp.sh << STOPEOF
#!/data/data/com.termux/files/usr/bin/bash
echo "Stopping XRDP and ${DE_NAME}..."
pkill -9 -f "xrdp-sesman" 2>/dev/null
pkill -9 -f "xrdp" 2>/dev/null
pkill -9 -f "pulseaudio" 2>/dev/null
${KILL_CMD} 2>/dev/null
pkill -9 -f "dbus" 2>/dev/null
echo "Remote desktop stopped."
STOPEOF
    chmod +x ~/stop-xrdp.sh
    echo -e "  [+] Created ~/stop-xrdp.sh"
}

# ============== STEP 11: CREATE SHORTCUTS ==============
step_shortcuts() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Creating Desktop Shortcuts...${NC}"
    echo ""
    mkdir -p ~/Desktop
    
    # App shortcuts
    cat > ~/Desktop/Firefox.desktop << 'EOF'
[Desktop Entry]
Name=Firefox
Exec=firefox
Icon=firefox
Type=Application
EOF



    cat > ~/Desktop/VLC.desktop << 'EOF'
[Desktop Entry]
Name=VLC Media Player
Exec=vlc
Icon=vlc
Type=Application
EOF

    cat > ~/Desktop/Wine_Config.desktop << 'EOF'
[Desktop Entry]
Name=Wine Config (Windows)
Exec=wine winecfg
Icon=wine
Type=Application
EOF

    # Dynamic terminal shortcut
    local term_cmd="xfce4-terminal"
    local term_icon="utilities-terminal"
    if [ "$DE_CHOICE" == "2" ]; then term_cmd="qterminal"; fi
    if [ "$DE_CHOICE" == "3" ]; then term_cmd="mate-terminal"; fi
    if [ "$DE_CHOICE" == "4" ]; then term_cmd="konsole"; fi
    
    cat > ~/Desktop/Terminal.desktop << EOF
[Desktop Entry]
Name=Terminal
Exec=${term_cmd}
Icon=${term_icon}
Type=Application
EOF

    chmod +x ~/Desktop/*.desktop 2>/dev/null
    echo -e "  [+] Added Firefox, VLC, Wine, and Terminal shortcuts."
}

# ============== STEP 12: CONNECTION INFO ==============
step_connection_info() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Generating connection info...${NC}"
    echo ""

    # Reusable script: IP can change (e.g. switched Wi-Fi), so the user
    # can re-run this anytime to get fresh connection details.
    cat > ~/rdp-info.sh << INFOEOF
#!/data/data/com.termux/files/usr/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'

usuario=\$(whoami)
porta=${RDP_PORT}
ip_local=\$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if (\$i=="src") print \$(i+1)}')

if [ -z "\$ip_local" ]; then
    ip_local=\$(ip -4 addr show 2>/dev/null | grep -oE 'inet [0-9.]+' | grep -v '127.0.0.1' | head -n1 | awk '{print \$2}')
fi
[ -z "\$ip_local" ] && ip_local="(nao detectado - rode 'ip addr' manualmente)"

echo ""
echo -e "\${CYAN}=========================================================\${NC}"
echo -e "\${WHITE}        COMO CONECTAR PELO WINDOWS (Remote Desktop)\${NC}"
echo -e "\${CYAN}=========================================================\${NC}"
echo -e "  \${WHITE}Endereco/IP:\${NC}  \${GREEN}\${ip_local}\${NC}"
echo -e "  \${WHITE}Porta:\${NC}       \${GREEN}\${porta}\${NC}"
echo -e "  \${WHITE}Usuario:\${NC}     \${GREEN}\${usuario}\${NC}"
echo -e "  \${WHITE}Senha:\${NC}       \${YELLOW}(a que voce definiu com 'passwd')\${NC}"
echo -e "\${CYAN}=========================================================\${NC}"
echo -e "  No Windows, abra \${WHITE}Conexao de Area de Trabalho Remota\${NC} (mstsc)"
echo -e "  e digite: \${GREEN}\${ip_local}:\${porta}\${NC}"
echo -e "\${CYAN}=========================================================\${NC}"
echo ""
echo -e "\${YELLOW}[!] O celular e o PC precisam estar na mesma rede Wi-Fi.\${NC}"
echo -e "\${YELLOW}[!] Se o IP mudar, rode de novo: \${WHITE}bash ~/rdp-info.sh\${NC}"
echo ""
INFOEOF
    chmod +x ~/rdp-info.sh
    echo -e "  [+] Created ~/rdp-info.sh (run anytime to see current connection info)"
    echo ""

    bash ~/rdp-info.sh
}


show_completion() {
    echo ""
    echo -e "${GREEN}"
    cat << 'COMPLETE'
    ---------------------------------------------------------------
             [*]  INSTALLATION COMPLETE!  [*]                      
    ---------------------------------------------------------------
COMPLETE
    echo -e "${NC}"
    
    echo -e "${WHITE}[*] Your ${DE_NAME} environment is ready.${NC}"
    echo -e "${CYAN}[*] Installed Software:${NC}"
    echo "    - Python (Flask Demo located in ~/demo_python)"
    echo "    - Firefox Browser & VLC Media Player"
    echo "    - Wine & Hangover (Windows PC App compatibility)"
    echo "    - GPU Hardware Acceleration Enabled"
    echo "    - XRDP Remote Desktop Server"
    echo ""
    echo -e "${YELLOW}------------------------------------------------------------${NC}"
    echo -e "${WHITE}[*] TO START THE DESKTOP:${NC}      ${GREEN}./start-xrdp.sh${NC}"
    echo -e "${WHITE}[*] TO STOP THE DESKTOP:${NC}       ${GREEN}./stop-xrdp.sh${NC}"
    echo -e "${WHITE}[*] CONNECTION INFO ANYTIME:${NC}   ${GREEN}./rdp-info.sh${NC}"
    echo -e "${YELLOW}------------------------------------------------------------${NC}"
    echo ""
    echo -e "${WHITE}[*] No Windows, abra 'Conexao de Area de Trabalho Remota' (mstsc)${NC}"
    echo -e "${WHITE}    e use o IP/usuario/senha mostrados acima.${NC}"
    echo ""
    echo -e "${YELLOW}[!] Observacoes:${NC}"
    echo -e "    - Celular e PC precisam estar na mesma rede Wi-Fi."
    echo -e "    - Mantenha o Termux aberto (nao remova da tela de apps recentes)"
    echo -e "      enquanto estiver usando a area de trabalho remota."
    echo -e "    - Audio dos apps toca no alto-falante do celular, nao e"
    echo -e "      redirecionado para o PC pelo XRDP."
    echo -e "    - XRDP costuma ser um pouco mais lento/instavel que o"
    echo -e "      Termux-X11 nativo (overhead de codificar a tela via RDP)."
    echo ""
}

# ============== MAIN ==============
main() {
    show_banner
    setup_environment
    
    step_update
    step_repos
    step_xrdp
    step_desktop
    step_gpu
    step_audio
    step_apps
    step_python
    step_wine
    step_launchers
    step_shortcuts
    step_connection_info
    
    show_completion
}

main
