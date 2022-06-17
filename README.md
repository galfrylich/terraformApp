# terraformApp

how to run this project?
Requriments
Terraform
Azure account
Azure CLI
Steps to run the project:
Conncte your Azure CLI to your Azure accont-az login.
Add secretVars.tfvars file with this content of variabls (the users names and passwords for you virtual machines.):

variable "admin_username" { default = "<userName>" }
variable "admin_password" { default = "<password>" }
variable "admin_usernameDb" { default = "<userName>" }
variable "admin_password" { default = "<password" }
Run terraform apply (in the project directory).
Now you can connect your machines through bastion in your azure portal and use the bash scripts (in the configureVMs_scripts directory) to inatall the app and the DB on them. (The bash scripts are not ready yet to run automaticlly, so copy-paste the commands to the machine CLI and change the .env file as you need for the machine IP address, the Public IP, password, etc.)
Terraform backend on azure storage
To upload the terraform state to azure storage, you need to cancel the comment inside the "backetStateConfiguration.tf" file. And change the storage attributes names to your own.

You need to run terraform init again, to apply the backend configuration.



