#!/bin/bash
# GPL 2.0, gfjardim, 2014

ask() {
    # http://djm.me/ask
    while true; do
        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        # Ask the question
        echo ''
        read -p "$1 [$prompt] " REPLY

        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi

        # Check if the reply is valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
    done
}

# Update sensors-detect
if ask "Do you want to update sensors-datect?" N; then
  wget -qO /tmp/sensors-detect http://dl.lm-sensors.org/lm-sensors/files/sensors-detect
  if [[ $? -eq 0 ]]; then
    cp -f /tmp/sensors-detect /usr/sbin/sensors-detect
    rm /tmp/sensors-detect
    chmod +x /usr/sbin/sensors-detect
  fi
fi

# Detect and import modules
yes "" | /usr/sbin/sensors-detect 1>/dev/null 2>&1
source /etc/sysconfig/lm_sensors

MODULES=""
for MOD in ${HWMON_MODULES}; do
  # Verify if module exist and can be loaded
  STATUS=$(modprobe -D ${MOD} 2>/dev/null)
  if [[ -n  ${STATUS} ]]; then
    MODULES+="${MOD} "
  fi
done

echo -e "\nThe following modules were found: ${MODULES}"

if ask "Do you want to load modules now?" Y; then
  for MOD in ${MODULE}S; do
    if [[ $(lsmod | grep -c ${MOD}) -eq 0 ]]; then
      modprobe ${MOD}
    fi
  done
fi

if ask "Do you want to load these modules on startup?" Y; then
  # Cleaning go file
  sed -i -n '/# Sensors drivers/{n;n;n;};1h;1!{x;p;};${x;p;}' /boot/config/go
  echo -e "\n# Sensors drivers\nmodprobe -a ${MODULES}\n" >> /boot/config/go
fi
