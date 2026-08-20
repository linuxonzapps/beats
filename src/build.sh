#!/bin/bash
set -e -o pipefail
read -ra arr <<< "$@"
version=${arr[1]}
trap 0 1 2 ERR
# Ensure sudo is installed
apt-get update && apt-get install sudo -y
# Extract DISTRO details for tagging
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="$ID-$VERSION_ID"
    if [ "$VERSION_CODENAME" != "" ]; then
        DISTRO="$ID-$VERSION_CODENAME"
    fi
fi
current_dir="$PWD"
echo $DISTRO > .distro_zab.txt
bash /tmp/linux-on-ibm-z-scripts/Beats/${version}/build_beats.sh -y
# Package beats
GO_VERSION=`awk -F'=' '/^GO_VERSION/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' /tmp/linux-on-ibm-z-scripts/Beats/${version}/build_beats.sh`
export GOROOT="/usr/local/go-${GO_VERSION}"
export PATH="$GOROOT/bin:$PATH"
export GOPATH=$(go env GOPATH)
cd $GOPATH/src/github.com/elastic/beats
# Filebeat
PKG_NAME="filebeat-${version}-linux-s390x"
mkdir -p ${PKG_NAME}
cp filebeat/filebeat ${PKG_NAME}/
cp filebeat/filebeat.yml filebeat/filebeat.reference.yml filebeat/fields.yml ${PKG_NAME}/
cp -r filebeat/modules.d filebeat/module/ ${PKG_NAME}/
cp LICENSE.txt NOTICE.txt filebeat/README.md ${PKG_NAME}/
# Auditbeat
PKG_NAME="auditbeat-${version}-linux-s390x"
mkdir -p ${PKG_NAME}
cp auditbeat/auditbeat ${PKG_NAME}/
cp auditbeat/auditbeat.yml auditbeat/auditbeat.reference.yml auditbeat/fields.yml ${PKG_NAME}/
cp LICENSE.txt NOTICE.txt README.md ${PKG_NAME}/
# Heartbeat
PKG_NAME="heartbeat-${version}-linux-s390x"
mkdir -p ${PKG_NAME}
cp heartbeat/heartbeat ${PKG_NAME}/
cp heartbeat/heartbeat.yml heartbeat/heartbeat.reference.yml heartbeat/fields.yml ${PKG_NAME}/
cp -r heartbeat/monitors.d ${PKG_NAME}/
cp LICENSE.txt NOTICE.txt heartbeat/README.md ${PKG_NAME}/
# Metricbeat
PKG_NAME="metricbeat-${version}-linux-s390x"
mkdir -p ${PKG_NAME}
cp metricbeat/metricbeat ${PKG_NAME}/
cp metricbeat/metricbeat.yml metricbeat/metricbeat.reference.yml metricbeat/fields.yml ${PKG_NAME}/
cp -r metricbeat/modules.d metricbeat/module/ ${PKG_NAME}/
cp LICENSE.txt NOTICE.txt metricbeat/README.md ${PKG_NAME}/
# Packetbeat
PKG_NAME="packetbeat-${version}-linux-s390x"
mkdir -p ${PKG_NAME}
cp packetbeat/packetbeat ${PKG_NAME}/
cp packetbeat/packetbeat.yml packetbeat/packetbeat.reference.yml packetbeat/fields.yml ${PKG_NAME}/
cp LICENSE.txt NOTICE.txt packetbeat/README.md ${PKG_NAME}/
# Package all Beats together
tar cvfz beats-${version}-linux-s390x.tar.gz -C $PWD filebeat-${version}-linux-s390x auditbeat-${version}-linux-s390x heartbeat-${version}-linux-s390x metricbeat-${version}-linux-s390x packetbeat-${version}-linux-s390x
# Move it to base directory for post processing
mv beats-${version}-linux-s390x.tar.gz ${current_dir}
exit 0
