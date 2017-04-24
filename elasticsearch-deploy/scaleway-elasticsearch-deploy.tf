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

#### INSTALLING ELASTICSEARCH AND KIBANA

	provisioner "remote-exec" {
	
	inline = [
		"export PATH=$PATH:/usr/bin",
		"sudo apt-get update",
		"sudo apt-get -y install default-jdk",
		"wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -",
		"sudo apt-get install apt-transport-https",
		"echo 'deb https://artifacts.elastic.co/packages/5.x/apt stable main' | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list",
		"sudo apt-get update",
		"sudo apt-get -y install elasticsearch",
		"sudo systemctl daemon-reload",
		"sudo systemctl enable elasticsearch",
		"sudo apt-get update",
		"sudo apt-get -y install kibana",
		"sudo systemctl daemon-reload",
		"sudo systemctl enable kibana",
		"sudo systemctl start kibana",
		"sudo apt-get install nginx",
		"sudo mkdir /etc/nginx/ssl"
    ]
}   

#### COPY .YML CONFIG FILES 

	provisioner "file" {
    source      = "./elasticsearch.yml"
    destination = "/etc/elasticsearch/elasticsearch.yml"
  }
  
  	provisioner "file" {
    source      = "./kibana.yml"
    destination = "/etc/kibana/kibana.yml"
  }
  
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
		"sudo ufw allow from $VPN_IP_RANGE to any port 5601",
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
		private_key = "${file("~/.ssh/YOUR-KEY-HERE")}"
 }
    
  }
