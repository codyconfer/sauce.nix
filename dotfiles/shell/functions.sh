#! /bin/bash

source "$HOME/.config/sauce/styles.sh"

_sauce_tool_registered() {
  case "$1" in
  bitwarden-cli) command -v bw >/dev/null 2>&1 ;;
  *) return 1 ;;
  esac
}

get_secret() {
  local item="${1:-}" field="${2:-password}" value=""

  if [ -z "$item" ]; then
    echo "usage: get_secret <item> [field]" >&2
    return 2
  fi

  if _sauce_tool_registered bitwarden-cli && command -v bw >/dev/null 2>&1; then
    value=$(bw get "$field" "$item" 2>/dev/null) || value=""
    if [ -n "$value" ]; then
      printf '%s\n' "$value"
      return 0
    fi
  fi

  echo "get_secret: secret '$item' (field '$field') not found in Bitwarden" >&2
  return 1
}

get_ips() {
  local allips ip ips=""
  if command -v ip >/dev/null 2>&1; then
    allips=($(ip -4 addr | grep -oE 'inet [0-9]+(\.[0-9]+){3}' | awk '{print $2}'))
  else
    allips=($(ifconfig 2>/dev/null | grep -oE 'inet [0-9]+(\.[0-9]+){3}' | awk '{print $2}'))
  fi
  for ip in "${allips[@]}"; do
    if [[ $ip != 127* ]] && [[ $ip != 172* ]]; then
      if [[ $ip == 10.* ]]; then
        ips="${ips}local IP:   ${cyan}${ip}${blue}"${linebreak}
      fi
    fi
  done
  if command -v tailscale >/dev/null 2>&1; then
    local ts_ip ts_domain
    ts_ip=$(tailscale ip --4 2>/dev/null | head -n1)
    if [ -n "$ts_ip" ]; then
      ts_domain=$(tailscale whois "$ts_ip" 2>/dev/null |
        grep -oE "$(hostname)[^[:space:]]*\.ts\.net" | head -n1)
      ips="${ips}tailnet:    ${cyan}${ts_ip} ${blue}"${linebreak}
      [ -n "$ts_domain" ] && ips="${ips}            ${ts_domain}"${linebreak}
    fi
  fi

  printf '%s' "$ips"
}

print_ips() {
  get_ips
}

_sauce_print_header() {
  local dateColor=$cyan
  local nameColor=$blue
  local date
  date=$(date +'%A, %b %d, %Y')
  local host=""
  if command -v figlet >/dev/null 2>&1; then
    host=$(figlet -f smslant "@$(hostname)" 2>/dev/null | sed "s/^/$(printf '%*s' "1" '')/")
  fi
  [ -n "$host" ] || host=" @$(hostname)"
  clear
  cat <<-_END_
${yellow}${line}${clear}
${nameColor}${host}${clear}${linebreak}
_END_
  cat <<-_END_ | sed "s/^/$(printf '%*s' "2" '')/"
${dateColor}${date}${clear}
${nameColor}$(whoami)@$(hostname)${clear}${linebreak}
${nameColor}$(get_ips)${clear}${linebreak}
_END_
  cat <<-_END_
${yellow}${line}${clear}${linebreak}
$(pretty_lights 3)${linebreak}${linebreak}
${magenta}${oil}${pad}across the universe divide...${clear}${linebreak}
${yellow}${line}${clear}${linebreak}
_END_
}

list_docker_containers() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "docker is not installed."
    return 1
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "The Docker daemon is not running."
    return 1
  fi
  local tmp_ifs=$IFS
  IFS=$'\n'
  local container=""
  local group=""
  for container_status in 'Up' 'Running' 'Restarting' 'Created' 'Paused' 'Exited' 'Stopped' 'Dead'; do
    group=""
    local container=""
    local ps_result=""
    local display_status=""
    case $container_status in
    Up)
      display_status="${green}${uparrow}${clear}"
      ;;
    Running)
      display_status="${green}${uparrow}${clear}"
      ;;
    Exited)
      display_status="${yellow}${dash}${clear}"
      ;;
    Stopped)
      display_status="${yellow}${dash}${clear}"
      ;;
    Dead)
      display_status="${red}${x}${clear}"
      ;;
    *)
      display_status=$container_status
      ;;
    esac
    for ps_result in $(docker ps -a --format "{{.Status}} | {{.Names}} | {{.Image}} | {{.Ports}}" 2>/dev/null | grep "${container_status} "); do
      container=""
      i=1
      while
        iter=$(echo "$ps_result" | cut -d\| -f$i | xargs)
        [ -n "$iter" ]
      do
        if [[ $i == 1 ]]; then
          :
        elif [[ $i == 2 ]]; then
          container="${container}${display_status} ${bold}${iter}${clear}\n"
        else
          container="${container}\t${dim}${iter}\n"
        fi
        i=$((i + 1))
      done
      group="${group}${container}"
    done
    if [[ $group != "" ]]; then
      echo -e "${group}"
    fi
  done
  IFS=$tmp_ifs
}

if ! command -v prime-run >/dev/null 2>&1; then
  prime-run() {
    __NV_PRIME_RENDER_OFFLOAD=1 \
      __VK_LAYER_NV_optimus=NVIDIA_only \
      __GLX_VENDOR_LIBRARY_NAME=nvidia \
      "$@"
  }
fi

update() {
  local repo="${SAUCE_REPO:-$HOME/sauce.nix}"
  local flake="${SAUCE_NIX_FLAKE:-/etc/nixos}"
  local unit="nixos-rebuild-switch-to-configuration.service"
  case "$(systemctl show --property=ActiveState --value "$unit")" in
  active|activating|reloading|deactivating)
    printf 'A NixOS activation is still running. Wait for it before updating.\n' >&2
    printf 'Inspect it with: systemctl status %s; systemctl list-jobs\n' "$unit" >&2
    return 1
    ;;
  esac
  git -C "$repo" pull --ff-only &&
    sudo nix flake update --flake "$flake" &&
    sudo nixos-rebuild switch --flake "$flake#${SAUCE_NIX_HOST:-$(hostname)}" "$@"
}

alias docker-containers='list_docker_containers'
alias sauce='sauce-rebuild'
alias sauce-cd='cd "${SAUCE_NIX_FLAKE:-$HOME/.sauce/nix}"'
