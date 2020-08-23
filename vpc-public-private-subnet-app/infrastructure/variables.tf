variable "vpc_cidr"{
    default = "10.0.0.0/24"
    description = "VPC CIDR block"
}

variable "public_subnet1_cidr_block" {
    description = "Public Subnet1 CIDR Block"
}

variable "public_subnet2_cidr_block" {
    description = "Public Subnet2 CIDR Block"
}

variable "public_subnet3_cidr_block" {
    description = "Public Subnet3 CIDR Block"
}

variable "private_subnet1_cidr_block" {
    description = "Private Subnet1 CIDR Block"
}

variable "private_subnet2_cidr_block" {
    description = "Private Subnet2 CIDR Block"
}

variable "private_subnet3_cidr_block" {
    description = "Private Subnet3 CIDR Block"
}