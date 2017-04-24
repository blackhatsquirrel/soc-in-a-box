#### TODO - ADD NGINX CONFIG

#### PROVIDER INFO

provider "scaleway" {
  #organization = "SET ORG AS ENV VARIABLE"
  #token        = "SET TOKEN AS ENV VARIABLE"
  region       = "ams1"
}

#### GET SCALEWAY UBUNTU XENIAL IMAGE UID

data "scaleway_image" "ubuntu" {
  architecture = "x86_64"
  name         = "Ubuntu Xenial"
}

#### CONFIGURE RESOURCE REQUIREMENTS
#### NOTE: ANYTHING SMALLER THAN VC1M WON'T HAVE ENOUGH RAM


resource "scaleway_server" "elk_test" {
  name  = "elk_test"
  image = "${data.scaleway_image.ubuntu.id}"
  type  = "VC1M"
  dynamic_ip_required = 1
  volume {
  size_in_gb = 20
  type       = "l_ssd"
  }

#### INSTALLING GRR

	provisioner "remote-exec" {
	
	inline = [
		"export PATH=$PATH:/usr/bin",
		"sudo apt-get update",
		"sudo wget https://raw.githubusercontent.com/google/grr/master/scripts/install_script_ubuntu.sh",
		"sudo bash install_script_ubuntu.sh",
		"sudo apt-get install nginx",
		"sudo mkdir /etc/nginx/ssl"
    ]
}   

#### COPY .YML CONFIG FILES 
  
    provisioner "file" {
    source      = "./default"
    destination = "/etc/nginx/sites-available/default"
  }
  
#### COPY OPENSSL FILES (create with: "sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt",)

    provisioner "file" {
    source      = "./nginx.key"
    destination = "/etc/nginx/ssl/nginx.key"
  }
  
    provisioner "file" {
    source      = "./nginx.crt"
    destination = "/etc/nginx/ssl/nginx.crt"
  }
  
#### INSTALL AND CONFIGURE UFW & FAIL2BAN
  
	provisioner "remote-exec" {
	
	inline = [
		"sudo apt-get -y install ufw",
		"sudo ufw allow ssh",
		"sudo ufw allow from $VPN_IP_RANGE to any port 8000",
		"sudo ufw allow from $VPN_IP_RANGE to any port 443",
		"sudo ufw allow from $VPN_IP_RANGE to any port 80",
		"sudo ufw default deny incomming",
		"sudo ufw default allow outgoing",
		"sudo ufw --force enable",
		"sudo apt-get -y install fail2ban",
		"sudo service fail2ban start",
		"sudo service elasticsearch restart",
		"sudo service kibana restart",
		"sudo service nginx restart"
    ]
}   

#### CONNECTION INFO 
  
	connection {
		type     = "ssh"
		user     = "root"
		private_key = "${file("~/.ssh/scaleway-dev-arm")}"
 }
    
  }
