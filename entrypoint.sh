#!/bin/bash
set -e

echo "#################################################"
echo "> Starting ${GITHUB_WORKFLOW}:${GITHUB_ACTION}"

# Available env
echo "INPUT_HOST: ${INPUT_HOST}"
echo "INPUT_PORT: ${INPUT_PORT}"
echo "INPUT_USER: ${INPUT_USER}"
echo "INPUT_PASS: ${INPUT_PASS}"
echo "INPUT_KEY: ${INPUT_KEY}"
echo "INPUT_LOCAL: ${INPUT_LOCAL}"
echo "INPUT_EXTRA: ${INPUT_EXTRA}"
echo "INPUT_REMOTE: ${INPUT_REMOTE}"
echo "INPUT_RUN_BEFORE: ${INPUT_RUNBEFORE}"
echo "INPUT_RUN_AFTER: ${INPUT_RUNAFTER}"

RUNBEFORE=$(echo "$INPUT_RUNBEFORE" | sed -e ':a;N;$!ba;s/\n/ \&\& /g' -e 's/ \&\& $//')
RUNAFTER=$(echo "$INPUT_RUNAFTER" | sed -e ':a;N;$!ba;s/\n/ \&\& /g' -e 's/ \&\& $//')

echo "RUNAFTER: $RUNAFTER"

if [ -z "$INPUT_KEY" ]
then # Password
  echo "> Exporting Password"
  export SSHPASS=$PASS

  [[ -n "${INPUT_RUNBEFORE}" ]] && {
    echo "> Executing commands before deployment"
    sshpass -e ssh -T -o StrictHostKeyChecking=no -p $INPUT_PORT $INPUT_USER@$INPUT_HOST "$RUNBEFORE"
  }


  echo "> Deploying now"
  if [ -z "$INPUT_EXTRA" ]
  then
    sh -c "sshpass -p $INPUT_PASS rsync -avhz --progress --stats -e  'ssh -o StrictHostKeyChecking=no -p $INPUT_PORT' $GITHUB_WORKSPACE/$INPUT_LOCAL $INPUT_USER@$INPUT_HOST:$INPUT_REMOTE"
  else
    EXTRA="$INPUT_EXTRA"
    sh -c "sshpass -p $INPUT_PASS rsync -avhz $EXTRA --progress --stats -e  'ssh -o StrictHostKeyChecking=no -p $INPUT_PORT' $GITHUB_WORKSPACE/$INPUT_LOCAL $INPUT_USER@$INPUT_HOST:$INPUT_REMOTE"
  fi

  [[ -n "${INPUT_RUNAFTER}" ]] && {
    echo "> Executing commands after deployment"
    echo "RUNAFTER is $RUNAFTER"
    sshpass -e ssh -T -o StrictHostKeyChecking=no -p $INPUT_PORT $INPUT_USER@$INPUT_HOST "$RUNAFTER"
  }


else # Private key
  pwd
  mkdir "/root/.ssh"

  echo "$INPUT_KEY" > "/root/.ssh/id_rsa"
  chmod 400 "/root/.ssh/id_rsa"

  echo "Host *" > "/root/.ssh/config"
  echo "  AddKeysToAgent yes" >> "/root/.ssh/config"
  echo "  IdentityFile /root/.ssh/id_rsa" >> "/root/.ssh/config"

  cat "/root/.ssh/config"

  ls -lha "/root/.ssh/"

  [[ -z "${INPUT_RUNBEFORE}" ]] && {
    echo "> Executing commands before deployment"
    sshpass -e ssh -o StrictHostKeyChecking=no -p $INPUT_PORT $INPUT_USER@$INPUT_HOST "$RUNBEFORE"
  }

  echo "> Deploying now"
  if [ -z "$INPUT_EXTRA" ]
  then
    sh -c "sshpass -e rsync -avhz --progress --stats -e 'ssh -o StrictHostKeyChecking=no -p $INPUT_PORT' $GITHUB_WORKSPACE/$INPUT_LOCAL $INPUT_USER@$INPUT_HOST:$INPUT_REMOTE"
  else
    EXTRA="$INPUT_EXTRA"
    sh -c "sshpass -e rsync -avhz --progress $EXTRA --stats -e 'ssh -o StrictHostKeyChecking=no -p $INPUT_PORT' $GITHUB_WORKSPACE/$INPUT_LOCAL $INPUT_USER@$INPUT_HOST:$INPUT_REMOTE"
  fi


  [[ -z "${INPUT_RUNAFTER}" ]] && {
    echo "> Executing commands after deployment"
    sshpass -e ssh -o StrictHostKeyChecking=no -p $INPUT_PORT $INPUT_USER@$INPUT_HOST "$RUNAFTER"
  }
fi


echo "#################################################"
echo "Completed ${GITHUB_WORKFLOW}:${GITHUB_ACTION}"
