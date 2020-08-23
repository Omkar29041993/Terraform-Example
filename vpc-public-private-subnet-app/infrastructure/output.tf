output "vpc_id" {
    value= aws_vpc.production-vpc.id
}

output "vpc_cidr" {
    value = aws_vpc.production-vpc.cidr_block
}

output "public_subnet1_id" {
    value = aws_subnet.public-subnet1.id
}

output "public_subnet2_id" {
    value = aws_subnet.public-subnet2.id
}

output "public_subnet3_id" {
    value = aws_subnet.public-subnet3.id
}

output "private_subnet1_id" {
    value = aws_subnet.private-subnet1.id
}

output "private_subnet2_id" {
    value = aws_subnet.private-subnet2.id
}

output "private_subnet3_id" {
    value = aws_subnet.private-subnet3.id
}