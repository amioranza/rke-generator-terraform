#!/usr/bin/env bash

outputFile=${1}-cluster.yml
outputDir=../rke

if [ $# -eq 0 ]; then
  echo "Need the environment parameter"
  exit 1
fi

for controller in $(cd ..; terraform workspace select ${1} >/dev/null; terraform output ctrl_address | sed s/,//); do # return only a list of controllers
  echo $controller
  controllers+=( $controller ) # feed an array with each element retuned by terraform output
done

for worker in $(cd ..; terraform workspace select ${1} >/dev/null; terraform output worker_address | sed s/,//); do # return only a list of workers 
  echo $worker
  workers+=( $worker ) # feed an array with each element retuned by terraform output
done

echo "Controllers"
echo ${controllers[*]} # print the elements of this array
echo "Workers"
echo ${workers[*]} # print the elements of this array

cat rke-header.yml > ${outputDir}/${outputFile}

for i in ${controllers[@]}; do # loop on array elements to generate this part of the file
  echo "- address: \"$i\"
  port: \"22\"
  role: [controlplane,etcd]
  user: \"svc_jenkins\"
  ssh_key_path: \"/home/svc_jenkins/.ssh/id_rsa\"
  labels: {} " >> ${outputDir}/${outputFile}
done

for i in ${workers[@]}; do # loop on array elements to generate this part of the file
  echo "- address: \"$i\"
  port: \"22\"
  role: [worker]
  user: \"svc_jenkins\"
  ssh_key_path: \"/home/svc_jenkins/.ssh/id_rsa\"
  labels: {} " >> ${outputDir}/${outputFile}
done
echo "
authentication:
    strategy: x509
    sans:" >> ${outputDir}/${outputFile}
for i in ${controllers[@]}; do
  echo "      - \"$i\"" >> ${outputDir}/${outputFile}
done

cat rke-footer.yml >> ${outputDir}/${outputFile}