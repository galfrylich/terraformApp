output "passwords" {
    description= "The passwords to connect the virtual machines"
    value = {
        admin_usernameDb= var.admin_usernameDb
        admin_password= var.admin_password
        admin_username= var.admin_username
        admin_password= var.admin_password
    }
}