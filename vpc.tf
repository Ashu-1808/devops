resource "aws_vpc" "vnet" {
    cidr_block = "192.168.0.0/16"
    tags = {
        Name = "nat-vpc"
    }
}

resource "aws_subnet" "pub" {
    vpc_id = aws_vpc.vnet.id
    cidr_block = "192.168.0.0/22"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "public-subnet"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vnet.id
    tags = {
        Name = "internet"
    }

}

resource "aws_route_table" "rt1" {
    vpc_id = aws_vpc.vnet.id
    tags = {
        Name = "RT-Public"
    }

    route {
        gateway_id = aws_internet_gateway.igw.id
        cidr_block = "0.0.0.0/0"
    }

}

resource "aws_route_table_association" "rta-1" {
    subnet_id = aws_subnet.pub.id
    route_table_id = aws_route_table.rt1.id


}

resource "aws_subnet" "pri" {
    vpc_id = aws_vpc.vnet.id
    cidr_block = "192.168.4.0/22"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = false
    tags = {
        Name = "subnet-private"
    }
        
    
}

resource "aws_eip" "static" {
    domain = "vpc"
}
 
resource "aws_nat_gateway" "nat"{
    subnet_id = aws_subnet.pub.id
    allocation_id = aws_eip.static.id
    tags = {
        Name = "nat-vpc"
    }

}
resource "aws_route_table" "rt2" {
    vpc_id = aws_vpc.vnet.id
    tags = {
      Name = "RT-Private"
    }

    route{
        nat_gateway_id = aws_nat_gateway.nat.id
        cidr_block = "0.0.0.0/0"
    }
} 
resource "aws_route_table_association" "rta-2" {
    subnet_id = aws_subnet.pri.id
    route_table_id = aws_route_table.rt2.id
}

resource "aws_security_group" "sg" {
    vpc_id = aws_vpc.vnet.id
    tags = {
        Name = "vpc-security"
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = [ "0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "vm-pri" {
    ami = "ami-00ca570c1b6d79f36"
    instance_type = "t3.micro"
    key_name = "linux"
    vpc_security_group_ids = [aws_security_group.sg.id]
    subnet_id = aws_subnet.pri.id
    tags = {
      Name = "TF-private-server"
    }
}

resource "aws_instance" "vm-pub" {
    ami = "ami-00ca570c1b6d79f36"
    instance_type = "t3.medium"
    key_name = "linux"
    subnet_id = aws_subnet.pub.id
    vpc_security_group_ids = [aws_security_group.sg.id]

    user_data = <<-EOF
        #!/bin/bash
        sleep 40
        sudo -i
        yum install httpd -y
        systemctl start httpd
        systemctl enable httpd
        echo "VPC WITH NAT GATEWAY HAS BEEN CREATED" > /var/www/html/index.html
      EOF
    tags = {
        Name = "TF-Public-server"
    }
}