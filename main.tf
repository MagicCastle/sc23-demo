terraform {
  required_version = ">= 1.4.0"
}

variable "pool" {
  description = "Slurm pool of compute nodes"
  default = []
}

module "aws" {
  cluster_name = ""
  guest_passwd = ""
  nb_users     = 10
  domain       = "magiccastle.live"

  instances = {
    mgmt  = { type = "t3.large",  count = 1, tags = ["mgmt", "puppet", "nfs"] },
    login = { type = "t3.medium", count = 1, tags = ["login", "public", "proxy"] },
    node  = { type = "t3.medium", count = 1, tags = ["node"] }
  }

  volumes = {
    nfs = {
      home     = { size = 10, type = "gp2" }
      project  = { size = 10, type = "gp2" }
      scratch  = { size = 10, type = "gp2" }
    }
  }

  # Rocky Linux 8 -  ca-central-1
  # https://rockylinux.org/cloud-images
  image        = "ami-09ada793eea1559e6"

  public_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBblyJ+6JynjS7kxzawodNvRrOTGVGj7266zcFJuq01N 1password_ed25519"]

  generate_ssh_key = true
  pool = var.pool
  # AWS specifics
  region            = "ca-central-1"

  source         = "git::https://github.com/ComputeCanada/magic_castle.git//aws?ref=13.1.0"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "13.1.0"
}

output "accounts" {
  value = module.aws.accounts
}

output "public_ip" {
  value = module.aws.public_ip
}

## Uncomment to register your domain name with CloudFlare
module "dns" {
  source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare"
  name             = module.aws.cluster_name
  domain           = module.aws.domain
  bastions         = module.aws.bastions
  public_instances = module.aws.public_instances
  ssh_private_key  = module.aws.ssh_private_key
  sudoer_username  = module.aws.accounts.sudoer.username
}

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.aws.cluster_name
#   domain           = module.aws.domain
#   bastions         = module.aws.bastions
#   public_instances = module.aws.public_instances
#   ssh_private_key  = module.aws.ssh_private_key
#   sudoer_username  = module.aws.accounts.sudoer.username
# }

output "hostnames" {
	value = module.dns.hostnames
}
