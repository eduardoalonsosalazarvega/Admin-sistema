#pedimos permiso de adminitrador
sudo su 
#hasta aqui vamos bien
apt -y install openssh-server
#ahora activamos el servicio
systemctl enable ssh
#ahora vamos a reiniciarlo 
systemctl restart ssh
#ahora habilitamos el firewall en el ssh
ufw allow ssh
ufw enable

