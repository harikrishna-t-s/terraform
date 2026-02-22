# Terraform Resource Library

A comprehensive collection of reusable Terraform modules for AWS infrastructure deployment.

## 🏗️ Module Structure

Each module follows a consistent structure:

``` bash
module-name/
├── main.tf          # Main resources
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── locals.tf        # Local values (if needed)
└── README.md        # Module documentation
```

## 📖 Usage Example

```hcl
module "vpc" {
  source = "./modules/vpc"

  environment = "production"
  vpc_cidr    = "10.0.0.0/16"

  tags = {
    Project = "my-app"
  }
}
```

## 🔧 Requirements

- Terraform >= 1.0.0
- AWS Provider >= 5.0
