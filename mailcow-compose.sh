#!/usr/bin/env bash
#
# docker-compose wrapper script for mailcow

#---------------------------------------
# functions
#---------------------------------------
function validate_input()
{
  if [[ "$#" -eq 0 ]]; then
    echo -e "\e[31mNo arguments given. Call this script with e.g. 'up -d' or 'down'\e[0m"
    exit 1
  fi

  if [[ ! -f mailcow.conf ]]; then
    echo -e "\e[31mmailcow.conf is missing! Is mailcow installed?\e[0m"
    exit 1
  fi

  source mailcow.conf
}

detect_docker_compose_command(){
  if ! [[ "${DOCKER_COMPOSE_VERSION}" == "native" ]] && ! [[ "${DOCKER_COMPOSE_VERSION}" == "standalone" ]]; then
    if command -v docker compose > /dev/null 2>&1; then
      version=$(docker compose version --short)
      if [[ $version =~ ^2\.([0-9]+)\.([0-9]+) ]]; then
        DOCKER_COMPOSE_VERSION=native
        COMPOSE_COMMAND="docker compose"
        echo -e "\e[31mFound Docker Compose Plugin (native).\e[0m"
        echo -e "\e[31mSetting the DOCKER_COMPOSE_VERSION Variable to native\e[0m"
        sleep 2
        echo -e "\e[33mNotice: You'll have to update this Compose Version via your Package Manager manually! \e[0m"
      else
        echo -e "\e[31mCannot find Docker Compose with a Version Higher than 2.X.X.\e[0m"
        echo -e "\e[31mPlease update/install it manually regarding to this doc site: https://mailcow.github.io/mailcow-dockerized-docs/i_u_m/i_u_m_install/\e[0m"
        exit 1
      fi
    elif command -v docker-compose > /dev/null 2>&1; then
      version=$(docker-compose version --short)
      if [[ $version =~ ^2\.([0-9]+)\.([0-9]+) ]]; then
        DOCKER_COMPOSE_VERSION=standalone
        COMPOSE_COMMAND="docker-compose"
        echo -e "\e[31mFound Docker Compose Standalone.\e[0m"
        echo -e "\e[31mSetting the DOCKER_COMPOSE_VERSION Variable to standalone\e[0m"
        sleep 2
        echo -e "\e[33mNotice: For an automatic update of docker-compose please use the update_compose.sh scripts located at the helper-scripts folder.\e[0m"
      else
        echo -e "\e[31mCannot find Docker Compose with a Version Higher than 2.X.X.\e[0m"
        echo -e "\e[31mPlease update/install regarding to this doc site: https://mailcow.github.io/mailcow-dockerized-docs/i_u_m/i_u_m_install/\e[0m"
        exit 1
      fi

    else
      echo -e "\e[31mCannot find Docker Compose.\e[0m"
      echo -e "\e[31mPlease install it regarding to this doc site: https://mailcow.github.io/mailcow-dockerized-docs/i_u_m/i_u_m_install/\e[0m"
      exit 1
    fi

  elif [[ "${DOCKER_COMPOSE_VERSION}" == "native" ]]; then
    COMPOSE_COMMAND="docker compose"

  elif [[ "${DOCKER_COMPOSE_VERSION}" == "standalone" ]]; then
    COMPOSE_COMMAND="${MAILCOW_DOCKER_COMPOSE:-"docker-compose"}"
  fi
}

function run_compose()
{
  if [[ -n "${DOCKER_COMPOSE_EXTRA_OVERRIDES}" ]]; then
    IFS=',' read -r -a overrides <<< "${DOCKER_COMPOSE_EXTRA_OVERRIDES}"
    COMPOSE_ARGUMENTS="-f docker-compose.yml "
    for override in "${overrides[@]}"; do
        COMPOSE_ARGUMENTS+="-f ${override} "
    done
  else
    COMPOSE_ARGUMENTS=""
  fi

  echo -e "\e[32mExecuting: ${COMPOSE_COMMAND} ${COMPOSE_ARGUMENTS} $@ \e[0m"
  ${COMPOSE_COMMAND} ${COMPOSE_ARGUMENTS} $@
}

#---------------------------------------
# main
#---------------------------------------
validate_input $@
detect_docker_compose_command
run_compose $@
