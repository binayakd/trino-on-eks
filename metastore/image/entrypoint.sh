#/bin/bash

set -e 

function log () {
    level=$1
    message=$2
    echo $(date  '+%d-%m-%Y %H:%M:%S') [${level}]  ${message}
}

function initSchema () {
  log "INFO" "checking DB schemas"
  if ${METASTORE_HOME}/bin/schematool -info -dbType postgres
  then
    log "INFO" "scheme found in DB"
  else
    log "INFO" "schema not found DB, running initSchema"
    ${METASTORE_HOME}/bin/schematool -initSchema -dbType postgres
  fi
}


if initSchema 
then 
  log "INFO" "starting metastore"
  ${METASTORE_HOME}/bin/start-metastore
else 
  log "ERROR" "error checking schema or running initSchema"
  exit 1
fi
