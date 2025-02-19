provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MainVPC"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "PublicSubnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"

  tags = {
    Name = "PrivateSubnet"
  }
}

resource "aws_security_group" "sg_web" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH (restrict in production)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebSecurityGroup"
  }
}

resource "aws_security_group" "sg_db" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_web.id] # Allow only backend SG
  }  

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DBSecurityGroup"
  }
}

resource "aws_instance" "frontend" {
  ami           = "ami-001adaa5c3ee02e10"  
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.sg_web.id]
  associate_public_ip_address = true

  tags = {
    Name = "FrontendServer"
  }
}

resource "aws_instance" "backend" {
  ami           = "ami-001adaa5c3ee02e10"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id
  security_groups = [aws_security_group.sg_web.id]  # Fix reference ✅

  tags = {
    Name = "BackendServer"
  }
}

resource "aws_db_instance" "database" {
  allocated_storage    = 20
  engine              = "mysql"
  engine_version      = "8.0.35"
  instance_class      = "db.t3.micro"
  db_name             = "mydb"
  username           = "admin"
  password           = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot = true
  publicly_accessible = false
  vpc_security_group_ids = [aws_security_group.sg_db.id]
 
 # Ensure the DB is in the same VPC as the EC2 instances
  
    db_subnet_group_name = aws_db_subnet_group.my_db_subnet_group.name  # ✅ Correct reference

  tags = {
    Name = "MyDatabase"
  }
}

resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.public_subnet.id] 

  tags = {
    Name = "DBSubnetGroup"
  }
}



resource "aws_lb" "app_lb" {
  name               = "myapp-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_web.id]
  subnets           = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]

  tags = {
    Name = "AppLoadBalancer"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "MainInternetGateway"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
