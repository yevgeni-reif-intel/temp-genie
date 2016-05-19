#!/bin/sh
# Get cluster parameters
echo "Please enter the cluster size: "
read cluster_size
  if (("$cluster_size" > "16")); then
      echo "Your cluster size must be less than 16"
      exit 0
fi

mkdir -p /tmp/dl-genie/
echo "[dlgenie]" > /tmp/dl-genie/amazon_hosts
for ((i = 1; i <= cluster_size; i++))
do
    echo "Please enter server ${i} IP: "
    read server_ip
    all_ips=$all_ips" $server_ip";#concatencate all ips

#    sed -i '1i"$server_ip"' /tmp/dl-genie/amazon_hosts
   echo "$server_ip" >> /tmp/dl-genie/amazon_hosts
done

echo "[dlgenie:vars]" >> /tmp/dl-genie/amazon_hosts
echo "ansible_ssh_user=core" >> /tmp/dl-genie/amazon_hosts
echo 'ansible_python_interpreter="PATH=/home/core/bin:$PATH python"' >> /tmp/dl-genie/amazon_hosts

echo "Please save your private key pem file as: /tmp/dl-genie/private-key.pem"
echo "Press any key when done..."
read dummy

DL_GENIE_ANSIBLE_CONTAINER=intelaa/dl-genie-ansible:0.0.1
DL_GENIE_ANSIBLE_CONTAINER_NAME=dl-genie-ansible

docker pull ${DL_GENIE_ANSIBLE_CONTAINER}
docker run --rm -it --volume=/tmp/dl-genie:/workspace --name ${DL_GENIE_ANSIBLE_CONTAINER_NAME} ${DL_GENIE_ANSIBLE_CONTAINER} ansible-playbook /etc/ansible/deploy_amazon_dlgenie.yml -i /workspace/amazon_hosts --private-key=/workspace/private-key.pem -vvvv

docker exec -it dlgenie /bin/bash /opt/configureSSHD.sh $all_ips
