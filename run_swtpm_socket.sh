#!/bin/bash

# ##########################################
# temporary directory the swtpm process will run in
# ${TMPDIR}/tpmstate will contain the TPM's internal state
# ${TMPDIR}/etc will contain all configuration info
# ##########################################

export TMPDIR=${TPMDIR:-/tmp/swtpm-${USER}}
export TPMSTATE=${TMPDIR}/tpmstate
export ETCDIR=${TMPDIR}/etc

# ##########################################
# kill any previous runs of swtpm in this directory
# ##########################################

if test -f ${TPMSTATE}/swtpm-pid
then
    echo "==> run_swtpm: killing previous instance pid=$(cat ${TPMSTATE}/swtpm-pid)"
    kill -9 $(cat ${TPMSTATE}/swtpm-pid)
fi

# ##########################################
# copy static configuration files to ${ETCDIR}
# ##########################################

rm -rf ${TPMSTATE} > /dev/null 2>&1
rm -rf ${ETCDIR} > /dev/null 2>&1
mkdir -p ${TPMSTATE} ${ETCDIR}
sed "s^%%etcdir%%^${ETCDIR}^g" cfg/swtpm_setup.conf.in > ${ETCDIR}/swtpm_setup.conf
cat cfg/swtpm-localca.conf.in | \
    sed "s^%%etcdir%%^${ETCDIR}^g" | \
    sed "s^%%statedir%%^${TPMSTATE}^g" > ${ETCDIR}/swtpm-localca.conf
cp cfg/swtpm-localca.options ${ETCDIR}

# ##########################################
# copy signing certificates to ${ETCDIR}
# these will be generated if not present.
# ##########################################

if test -f certs/issuercert.pem && test -f certs/signkey.pem
then
    cp -f certs/issuercert.pem ${ETCDIR}
    cp -f certs/signkey.pem ${ETCDIR}
fi

# ##########################################
# run TPM provisioning
# ##########################################

if ! type -P swtpm_setup > /dev/null 2>&1
then
    echo "==> cannot find swtpm_setup. swtpm is not correctly installed."
    exit 1
fi

if ! type -P swtpm_localca > /dev/null 2>&1
then
    echo "==> cannot find swtpm_localca. swtpm is not correctly installed."
    exit 1
fi

echo "===== running TPM provisioning ==== "
mkdir -p ${TPMSTATE}/swtpm-localca
if ! swtpm_setup \
    --tpmstate ${TPMSTATE} \
    --config ${ETCDIR}/swtpm_setup.conf \
    --tpm2 \
    --create-platform-cert \
    --create-ek-cert \
    --logfile ${TPMSTATE}/setup.log
then
    echo "==>     provisioning failed."
    cat ${TPMSTATE}/setup.log
    exit 1
fi

# ##########################################
# run swtpm
# ##########################################

echo "===== running swtpm ====="
if ! swtpm socket \
      -d \
      --tpmstate dir=${TPMSTATE},mode=0600 \
      --tpm2 \
      --ctrl type=unixio,path=${TPMSTATE}/swtpm-sock \
      --pid file=${TPMSTATE}/swtpm-pid \
      --log level=20,file=${TPMSTATE}/swtpm.log
then
    echo "==> swtpm run failed."
    cat ${TPMSTATE}/swtpm.log
    exit 1
fi

# ##########################################
# 
# ##########################################

echo "==> run_swtpm socket ready: ${TPMSTATE}/swtpm-sock"
