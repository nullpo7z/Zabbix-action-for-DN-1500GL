#!/bin/bash
ZABBIX_API_KEY=""
ZABBIX_URL=""
DN1500GL_PASSWD=""
DN1500GL_ADDR=""

if [ $2 -eq 1 ] && [ $3 -eq 0 ]; then
  if [ $1 -eq 0 ]; then
    # Not_classified
    sudo rsh ${DN1500GL_ADDR} ACOP xx2xxxxx -p ${DN1500GL_PASSWD}
    sudo rsh ${DN1500GL_ADDR} ACOP xxxx1xxx -t 10 -p ${DN1500GL_PASSWD}
  elif [ $1 -eq 1 ]; then
    # Information
    sudo rsh ${DN1500GL_ADDR} ACOP xx3xxxxx -p ${DN1500GL_PASSWD}
    sudo rsh ${DN1500GL_ADDR} ACOP xxxx1xxx -t 10 -p ${DN1500GL_PASSWD}
  elif [ $1 -eq 2 ]; then
    # Warning
    sudo rsh ${DN1500GL_ADDR} ACOP x2xxxxxx -p ${DN1500GL_PASSWD}
    sudo rsh ${DN1500GL_ADDR} ACOP xxxx1xxx -t 30 -p ${DN1500GL_PASSWD}
  elif [ $1 -eq 3 ]; then
    # Average
    sudo rsh ${DN1500GL_ADDR} ACOP x3xxxxxx -p ${DN1500GL_PASSWD}
    sudo rsh ${DN1500GL_ADDR} ACOP xxxx1xxx -t 30 -p ${DN1500GL_PASSWD}
  elif [ $1 -eq 4 ]; then
    # High
    sudo rsh ${DN1500GL_ADDR} ACOP 2xxxxxxx -p ${DN1500GL_PASSWD}
    sudo rsh ${DN1500GL_ADDR} ACOP xxx1xxxx -t 60 -p ${DN1500GL_PASSWD}
  elif [ $1 -eq 5 ]; then
    # Disaster
    sudo rsh ${DN1500GL_ADDR} ACOP 3xxxxxxx -p ${DN1500GL_PASSWD}
    sudo rsh ${DN1500GL_ADDR} ACOP xxx1xxxx -t 60 -p ${DN1500GL_PASSWD}
  fi
elif [ $2 -eq 0 ] || [ $3 -eq 1 ]; then
    # Define an associative array that counts the number of each severity
  declare -A severity_counts

  # Initialize the array
  for i in {0..5}; do
    severity_counts[$i]=0
  done

  # Get problems status from Zabbix server
  JSON_DATA=$(curl -s -k -d "$(cat <<EOF
  {
      "auth": "${ZABBIX_API_KEY}",
      "method": "problem.get",
      "id": 1,
      "params": {
          "output": "extend"
      },
      "jsonrpc": "2.0"
  }
EOF
  )" -H "Content-Type: application/json-rpc" "${ZABBIX_URL}")

  # Extract only unsuppressed problems
  EXTRACTED_JSON=$(echo "${JSON_DATA}" | jq '.result[] | select(.suppressed == "0")')

  # Count the number of problems for each severity level
  while read -r severity; do
    ((severity_counts[${severity}]++))
  done < <(echo "${EXTRACTED_JSON}" | jq -r '.severity')
  
  if [ $1 -eq 0 ]; then
    if [ ${severity_counts[0]} -eq 0 ]; then
      if [ ${severity_counts[1]} -eq 0 ]; then
        # stop green light
        sudo rsh ${DN1500GL_ADDR} ACOP xx0xxxxx -p ${DN1500GL_PASSWD}
      elif [ ${severity_counts[1]} -ne 0 ]; then
        # Information
        sudo rsh ${DN1500GL_ADDR} ACOP xx3xxxxx -p ${DN1500GL_PASSWD}
      fi
    fi
  elif [ $1 -eq 1 ]; then
    if [ ${severity_counts[1]} -eq 0 ]; then
      if [ ${severity_counts[0]} -eq 0 ]; then
        # stop green light
        sudo rsh ${DN1500GL_ADDR} ACOP xx0xxxxx -p ${DN1500GL_PASSWD}
      elif [ ${severity_counts[0]} -ne 0 ]; then
        # Not_classified
        sudo rsh ${DN1500GL_ADDR} ACOP xx2xxxxx -p ${DN1500GL_PASSWD}
      fi
    fi
  elif [ $1 -eq 2 ]; then
    if [ ${severity_counts[2]} -eq 0 ]; then
      if [ ${severity_counts[3]} -eq 0 ]; then
        # stop yellow light
        sudo rsh ${DN1500GL_ADDR} ACOP x0xxxxxx -p ${DN1500GL_PASSWD}
      elif [ ${severity_counts[3]} -ne 0 ]; then
        # Average
        sudo rsh ${DN1500GL_ADDR} ACOP x3xxxxxx -p ${DN1500GL_PASSWD}
      fi
    fi
  elif [ $1 -eq 3 ]; then
    if [ ${severity_counts[3]} -eq 0 ]; then
      if [ ${severity_counts[2]} -eq 0 ]; then
        # stop yellow light
        sudo rsh ${DN1500GL_ADDR} ACOP x0xxxxxx -p ${DN1500GL_PASSWD}
      elif [ ${severity_counts[2]} -ne 0 ]; then
        # Warning
        sudo rsh ${DN1500GL_ADDR} ACOP x2xxxxxx -p ${DN1500GL_PASSWD}
      fi
    fi
  elif [ $1 -eq 4 ]; then
    if [ ${severity_counts[4]} -eq 0 ]; then
      if [ ${severity_counts[5]} -eq 0 ]; then
        # stop red light
        sudo rsh ${DN1500GL_ADDR} ACOP 0xxxxxxx -p ${DN1500GL_PASSWD}
      elif [ ${severity_counts[5]} -ne 0 ]; then
        # Disaster
        sudo rsh ${DN1500GL_ADDR} ACOP 3xxxxxxx -p ${DN1500GL_PASSWD}
      fi
    fi
  elif [ $1 -eq 5 ]; then
    if [ ${severity_counts[5]} -eq 0 ]; then
      if [ ${severity_counts[4]} -eq 0 ]; then
        # stop red light
        sudo rsh ${DN1500GL_ADDR} ACOP 0xxxxxxx -p ${DN1500GL_PASSWD}
      elif [ ${severity_counts[4]} -ne 0 ]; then
        # High
        sudo rsh ${DN1500GL_ADDR} ACOP 2xxxxxxx -p ${DN1500GL_PASSWD}
      fi
    fi
  fi
fi
