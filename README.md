# Steps to write a file

1. Create VPC
2. Internet Gateway
3. Custom Route Table
4. Subnet
5. Associate subnet with route table
6. Create security group to allow port 22,80,443
7. Add network interface with an ip the subnet that was created in step 4
8. Assign an elastic IP to the network interface created in step 7
9. Create Ubuntu server and install/enable apache2
10. Take output public ip after finishing

Export you AWS credentials in terminal, print terraform init, plan and apply
