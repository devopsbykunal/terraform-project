terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.37.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# Create a VPC
resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "swiggy-VPC"
  }
}

# Create Web Public Subnets
resource "aws_subnet" "web-subnet-1" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Web-1a"
  }
}

resource "aws_subnet" "web-subnet-2" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Web-2a"
  }
}

# Create Application Private Subnets
resource "aws_subnet" "application-subnet-1" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Application-1a"
  }
}

resource "aws_subnet" "application-subnet-2" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "Application-2b"
  }
}

# Create Database Private Subnets
resource "aws_subnet" "database-subnet-1" {
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "Database-1a"
  }
}

resource "aws_subnet" "database-subnet-2" {
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name = "Database-2b"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "SWIGGY-IGW"
  }
}

# Create Web Layer Route Table
resource "aws_route_table" "web-rt" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "WebRT"
  }
}

# Create Web Subnet Association with Web Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.web-subnet-1.id
  route_table_id = aws_route_table.web-rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.web-subnet-2.id
  route_table_id = aws_route_table.web-rt.id
}

# Create EC2 Instances
resource "aws_instance" "webserver1" {
  ami                    = "ami-0249211c9916306f8"
  instance_type          = "t3.micro"
  availability_zone      = "eu-north-1a"
  key_name               = "apr6pm"
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]
  subnet_id              = aws_subnet.web-subnet-1.id
  user_data              = file("apache.sh")

  tags = {
    Name = "Web Server 1"
  }
}

resource "aws_instance" "webserver2" {
  ami                    = "ami-0249211c9916306f8"
  instance_type          = "t3.micro"
  availability_zone      = "eu-north-1b"
  key_name               = "apr6pm"
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]
  subnet_id              = aws_subnet.web-subnet-2.id
  user_data              = file("apache.sh")

  tags = {
    Name = "Web Server 2"
  }
}

resource "aws_instance" "appserver1" {
  ami                    = "ami-0249211c9916306f8"
  instance_type          = "t3.micro"
  availability_zone      = "eu-north-1a"
  key_name               = "apr6pm"
  vpc_security_group_ids = [aws_security_group.appserver_sg.id]
  subnet_id              = aws_subnet.application-subnet-1.id

  tags = {
    Name = "App Server 1"
  }
}

resource "aws_instance" "appserver2" {
  ami                    = "ami-0249211c9916306f8"
  instance_type          = "t3.micro"
  availability_zone      = "eu-north-1b"
  key_name               = "apr6pm"
  vpc_security_group_ids = [aws_security_group.appserver_sg.id]
  subnet_id              = aws_subnet.application-subnet-2.id

  tags = {
    Name = "App Server 2"
  }
}

# Create RDS Instance
resource "aws_db_instance" "default" {
  allocated_storage      = 10
  db_subnet_group_name   = aws_db_subnet_group.default.id
  engine                 = "mysql"
  engine_version         = "8.0.28"
  instance_class         = "db.t2.micro"
  multi_az               = false
  db_name                = "mydb"
  username               = "kunal"
  password               = "kunal@2002"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.database_sg.id]
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.database-subnet-1.id, aws_subnet.database-subnet-2.id]

  tags = {
    Name = "My DB Subnet Group"
  }
}

# Create Security Groups
resource "aws_security_group" "webserver_sg" {
  name        = "webserver-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-SG"
  }
}

resource "aws_security_group" "appserver_sg" {
  name        = "appserver-sg"
  description = "Allow inbound traffic from ALB"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description = "Allow traffic from web layer"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow traffic from web layer"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "App-SG"
  }
}

resource "aws_security_group" "database_sg" {
  name        = "database-sg"
  description = "Allow inbound traffic from application layer"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description = "Allow traffic from application layer"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database-SG"
  }
}

# Create Application Load Balancer
resource "aws_lb" "external_elb" {
  name               = "External-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.webserver_sg.id]
  subnets            = [aws_subnet.web-subnet-1.id, aws_subnet.web-subnet-2.id]
}

resource "aws_lb_target_group" "external_elb" {
  name     = "ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my-vpc.id
}

resource "aws_lb_target_group_attachment" "external_elb1" {
  target_group_arn = aws_lb_target_group.external_elb.arn
  target_id        = aws_instance.webserver1.id
  port             = 80

  depends_on = [
    aws_instance.webserver1,
  ]
}

resource "aws_lb_target_group_attachment" "external_elb2" {
  target_group_arn = aws_lb_target_group.external_elb.arn
  target_id        = aws_instance.webserver2.id
  port             = 80

  depends_on = [
    aws_instance.webserver2,
  ]
}

resource "aws_lb_listener" "external_elb" {
  load_balancer_arn = aws_lb.external_elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external_elb.arn
  }
}

output "lb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.external_elb.dns_name
}

# Create S3 Bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "batch4pmdevopswithaws202477"

  acl    = "private"
  versioning {
    enabled = true
  }
}

# Create IAM Users
resource "aws_iam_user" "one" {
  for_each = var.iam_users
  name     = each.value
}

variable "iam_users" {
  description = "List of IAM users"
  type        = set(string)
  default     = ["user1", "user2", "user3", "user4"]
}

# Create IAM Group
resource "aws_iam_group" "two" {
  name = "devopswithkunaljoshi"
}
