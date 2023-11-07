# trigget it in one shoot
# sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/frani/tools/main/install-docker-nginx-ubuntu.sh)"

sudo apt update -y
sudo apt install nginx apt-transport-https ca-certificates curl software-properties-common -y
sudo ufw allow 'Nginx HTTP'
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-cache policy docker-ce
sudo apt update
sudo apt install docker-ce -y 
sudo usermod -aG docker ${USER}
sudo usermod -aG docker username
sudo apt install certbot python3-certbot-nginx -y
