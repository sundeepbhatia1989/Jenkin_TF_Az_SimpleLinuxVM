terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}
#Create SP account if you want to run terraform in jenking. 
#az account set --subscription="SUBSCRIPTION_ID"
#az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/SUBSCRIPTION_ID"

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = "81d74218-6f1e-4599-9ff5-eee7b8bbf6e0"
  #client_id       = ""
  #client_secret   = ""
  #tenant_id       = ""
}

# AUTH - Authenticating to Azure using a Service Principal and a Client Secret
# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "myResourceGroup"
    location = "eastus"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    tags = {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefixes       = ["10.0.2.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.myterraformgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "myNIC"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.myterraformgroup.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.myterraformnic.id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

/*# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.myterraformgroup.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.myterraformgroup.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}
*/
# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { 
    value = tls_private_key.example_ssh.private_key_pem 
    sensitive = true
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
    name                  = "myVM"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.myterraformgroup.name
    network_interface_ids = [azurerm_network_interface.myterraformnic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "myvm"
    admin_username = "azureuser"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "azureuser"
        public_key     = file("~/.ssh/id_rsa.pub")
        #public_key     = file("~/.ssh/id_rsa.pub") In jenking, we need to add public key manaully or user azure key-vault
        #/home/ubuntu/.ssh/
    }
/*
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }
*/
    tags = {
        environment = "Terraform Demo"
    }
}


/*Some important commands and links
TF installed
https://www.coachdevops.com/2019/02/install-terraform-on-ubuntu.html?showComment=1633368887176

VC code installed
https://linuxhint.com/install-visual-studio-code-ubuntu22-04/

Azure CLI
https://fabianlee.org/2021/05/29/azure-installing-the-azure-cli-on-ubuntu/

 Choosing a Subscription
 https://www.makeuseof.com/install-set-up-azure-cli-on-ubuntu/
 
 get sub id and tenant id
 az account list -o table
 
 Deployed simple linux vm in azure
 https://gist.github.com/devops-school/af6e449965a337a90eba3c454f9d41f0
 https://www.devopsschool.com/blog/terraform-example-program-to-create-linux-vm/
 
 
 Good link for openfoam
 https://awstip.com/deploying-azure-linux-vm-with-openfoam-using-terraform-a81df849efa6
 
 create random storage account name in terrafrom
 https://davecore82.github.io/Create-an-Ubuntu-Pro-VM-with-infrastructure-in-Azure-using-Terraform/
 
 generate ubuntu key
 https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-20-04
 
 terrafrom cheet sheet
 https://acloudguru.com/blog/engineering/the-ultimate-terraform-cheatsheet
 
 terraform init 
 terraform apply --auto-approve
 terraform plan -out plan.out
 sudo apt install graphviz
 terraform graph | dot -Tpng > graph.png
 
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
You can now use the SSH command to connect the Linux VM:
ssh hiteshj@public-ip
go to azure vm >>ssh>> give private key(location private where you given in terrafrom and generate ubuntu key)  like  ~/ssh/id_rsa.pem    ~/ssh/<private key>.pem
ssh -i ~/ssh/id_rsa.pem azureuser@13.68.247.168   ssh -i ~/ssh/<privatekey>.pem azureuser@<public ip> 

ubuntu@ubuntu-VirtualBox:~/.ssh$ ssh -i ~/ssh/id_rsa.pem azureuser@13.68.247.168
Warning: Identity file /home/ubuntu/ssh/id_rsa.pem not accessible: No such file or directory.
The authenticity of host '13.68.247.168 (13.68.247.168)' can't be established.
ED25519 key fingerprint is SHA256:fO4daTz6rtEIB7jyPNgEUMtY4jHoiRdQIZp2u9to+kk.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? Yes
Warning: Permanently added '13.68.247.168' (ED25519) to the list of known hosts.
Welcome to Ubuntu 18.04.6 LTS (GNU/Linux 5.4.0-1100-azure x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
azureuser@myvm:~$ ls
+++++++++++++++++++++++++++++++++++++++
*/