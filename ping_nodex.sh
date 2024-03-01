NUM_VMS=$1
TARGET_NODE="node$2"
BRIDGE_PREFIX=$3

if [ "$#" -ne 3 ]
then
  echo "run like: ping_nodex.sh [NUM_VMS]10 [TARGET_NODE]1 [BRIDGE_PREFIX]192.167"
  exit 1
fi

for (( SB_ID=3 ; SB_ID<${NUM_VMS} ; SB_ID++ ));
do
        sleep 5
        ## like so parallel_start_many START_VM END_VM BRIDGE_PREFIX
        ssh ag4786@${TARGET_NODE} bash parallel_start_many 1 ${SB_ID} ${BRIDGE_PREFIX}
        sleep 5
        bash collect_ping_metrics.sh 1 ${SB_ID} ${BRIDGE_PREFIX} >> ping_results
        sleep 5
        ssh -tt ag4786@${TARGET_NODE} "sudo bash cleanup 1 ${SB_ID}"
        sleep 5
done