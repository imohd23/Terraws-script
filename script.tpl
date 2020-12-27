#!/bin/bash
#* wait until efs mount is finished
sleep 2m
#* update the instnce
sudo yum update -y
sudo yum install git -y 
#* install the efs client 
sudo yum install -y amazon-efs-utils
#* make the target mount
sudo mkdir /efs
#* mount the efs
sudo mount -t efs -o tls ${efs_id}:/ /efs
#* insure if the instance got rebooted, the instance will remount  efs 
echo '${efs_id} ${efs_mount_id} /efs _netdev,tls,accesspoint=${efs_access_point_id} 0 0' >> /etc/fstab
#* install docker
sudo yum install -y docker
#* let it be run without sudo
sudo usermod -a -G docker ec2-user
#* start docker engine
sudo service docker start
sudo chkconfig docker on
#* install docker-compose
sudo curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-`uname -s`-`uname -m` | sudo tee /usr/local/bin/docker-compose > /dev/null
#* make it executable
sudo chmod +x /usr/local/bin/docker-compose
#* link docker-compose with bin folder so it can be called globally
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
#* give it permission to work without sudo
sudo usermod -a -G docker-compose ec2-user
#* make folders that docker-compose.yaml needs for volumes
sudo mkdir /efs/db /efs/wordpress
#* run docker-compose.yaml
sudo git clone https://github.com/imohd23/aws_TerraPress.git /home/ec2-user/aws_TerraPress
sudo docker-compose -f /home/ec2-user/aws_TerraPress/docker-compose.yaml up --build -d