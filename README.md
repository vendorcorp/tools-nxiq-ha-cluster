# TOOLS: Sonatype IQ Server HA Cluster

This repository uses our [Terraform Module](https://github.com/vendorcorp/terraform-aws-eks-nxiq) to build and manage multiple Sonatype IQ Server HA instances in Vendor Corp with separation provided by [Terraform Workspaces](https://developer.hashicorp.com/terraform/language/v1.1.x/state/workspaces).

**A valid Sonatype License is required in this projects root directory named `sonatype-license.lic` for this code to work.**

## READ THIS FIRST

You need to have installed `aws-vault`, `aws-cli` and configured your access before you can run anything.

Read more here to understand how to do this.

The rest of this documentation assumes you have created an AWS Vault profile called `vendorcorp`.

## Technologies Used

- [Terraform](https://www.terraform.io/downloads.html) v1.0.11: What you'll find in this repository!
- AWS Vault: You need this to access Sonatype AWS Accounts

## Running Terraform

For each NXIQ Cluster, change to a separate Terraform Workspace:
```
aws-vault exec vendorcorp -- terraform workspace new <NAME-HERE>
```

You can see existing Terraform Workspace by running:
```
aws-vault exec vendorcorp -- terraform workspace list
```

Use Terraform:
```
aws-vault exec vendorcorp -- terraform init
aws-vault exec vendorcorp -- terraform plan
aws-vault exec vendorcorp -- terraform apply
```

# The Fine Print

At the time of writing I work for Sonatype, and it is worth nothing that this is **NOT SUPPORTED** bu Sonatype - it is purely a contribution to the open source community (read: you!).

Remember:
- Use this contribution at the risk tolerance that you have
- Do NOT file Sonatype support tickets related to cheque support in regard to this project
- DO file issues here on GitHub, so that the community can pitch in