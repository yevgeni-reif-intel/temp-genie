#!/bin/sh
# Get cluster parameters
echo "Please enter the cluster size: "
read cluster_size
if (("$cluster_size" > "32")); then
    echo "Your cluster size must be less than 32"
    exit 0
fi

mkdir -p $HOME/dl-genie/
echo "[dlgenie]" > $HOME/dl-genie/amazon_hosts
for ((i = 1; i <= cluster_size; i++))
do
    echo "Please enter server ${i} IP: "
    read server_ip
    all_ips=$all_ips" $server_ip";#concatencate all ips
    echo "$server_ip" >> $HOME/dl-genie/amazon_hosts
done

echo "[dlgenie:vars]" >> $HOME/dl-genie/amazon_hosts
echo "ansible_ssh_user=core" >> $HOME/dl-genie/amazon_hosts
echo 'ansible_python_interpreter="PATH=/home/core/bin:$PATH python"' >> $HOME/dl-genie/amazon_hosts

#check if private-key exists
while [ ! -f $HOME/dl-genie/private-key.pem ]
do
    echo "Private key could not be found. Please save your private key pem file as: $HOME/dl-genie/private-key.pem"
    echo "Press any key when done..."
    read dummy
done

DL_GENIE_ANSIBLE_CONTAINER=intelaa/dl-genie-ansible:0.0.1
DL_GENIE_ANSIBLE_CONTAINER_NAME=dl-genie-ansible

docker pull ${DL_GENIE_ANSIBLE_CONTAINER}
docker run --rm -it --volume=$HOME/dl-genie:/workspace --name ${DL_GENIE_ANSIBLE_CONTAINER_NAME} ${DL_GENIE_ANSIBLE_CONTAINER} ansible-playbook /etc/ansible/deploy_amazon_dlgenie.yml -i /workspace/amazon_hosts --private-key=/workspace/private-key.pem -vvvv

docker exec -i dlgenie sh -c 'cat > ~/.ssh/private-key.pem' < $HOME/dl-genie/private-key.pem
docker exec -i dlgenie sh -c 'cat > ~/.ssh/config' < "IdentityFile ~/.ssh/private-key.pem"
docker exec -it dlgenie /bin/bash /opt/configureSSHD.sh $all_ips
