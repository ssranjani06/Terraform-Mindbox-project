

# Creating the VPC 

resource "aws_vpc" "webapp-vpc" {
  cidr_block       = "10.10.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Webapp-VPC"
  }
}


#creating subnet

resource "aws_subnet" "webapp-public-subnet-1a" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.10.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Webapp-public-subnet-1A"
  }
}
resource "aws_subnet" "webapp-private-subnet-1a" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Webapp-private-subnet-1A"
  }
}



resource "aws_subnet" "webapp-public-subnet-1b" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "Webapp-public-subnet-1B"
  }
}


resource "aws_subnet" "webapp-private-subnet-1b" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.10.3.0/24"
  availability_zone = "ap-south-1b"
  
  tags = {
    Name = "Webapp-subnet-1B"
  }
}


 resource "aws_key_pair" "ranjani-keypair" {
  key_name   = "ranjani-keypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDPHGkph/EjgARLn+dhMxJDNBgTHln/You8hC7IKcx7sITKnNagiElwUOcdVOg0nWsvzj4Yl2n8JQrQczYKcCHZace/8QmHlc/WmHwCJfNCPi7T2QPJKaLYh71qfyKAGSgTjka0OhtNMVqTZwKPzW76CA/zjXwyU5G5Q3hPgLzjKwf7VWaBFWGcW3E/5yn8AFMmApXE3JiCKUw1raJxiVP1tL4BgCVjRbV3XiVsD4zHReOCy/sEV9kTCyMj6m/QuLxbAI4BN+FqoYYuM+wLMAHwYYt6b/hQpRFEfnspTz/v26iISlJtvBdwzhjvlm9jSmOG2fRLKP61S4/qOyKPQakMgwXXExqNo/fV+U+HYnYT1xfUNmKXzw0I9Y7U1wMT8jJRpPQwIvO+CuIYBGHf86bLaEpgb08VGPPgvGj7qeySOO5nWdeqh/fzZvqm5TTZRLrDAjbziIo24mBduAE9Nm6v9Nm2RG2X+W2H6AIMH3OmGOjYxfxJtPcEso6ERNGiFGs= ssarav252@INSML-0Y3XQ4Y"
 }

# Internet GW

resource "aws_internet_gateway" "webapp-IGW" {
  vpc_id = aws_vpc.webapp-vpc.id

  tags = {
    Name = "Webapp-IGW"
  }
}

# Route Table

resource "aws_route_table" "webapp-RT" {
  vpc_id = aws_vpc.webapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.webapp-IGW.id
  }

  tags = {
    Name = "Webapp-RT"
  }
}

resource "aws_route_table_association" "webapp-RT-asso-01" {
  subnet_id      = aws_subnet.webapp-public-subnet-1a.id
  route_table_id = aws_route_table.webapp-RT.id
}


resource "aws_route_table_association" "webapp-RT-asso-02" {
  subnet_id      = aws_subnet.webapp-public-subnet-1b.id
  route_table_id = aws_route_table.webapp-RT.id
}

# Security Group

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.webapp-vpc.id

  ingress {
    description      = "ssh from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  
  ingress {
    description      = "http from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALLOW_SSH"
  }
}
#launch Template
resource "aws_launch_template" "webapp-launch-template" {
  name = "webapp-launch-template"
  image_id = "ami-02eb7a4783e7e9317"
  instance_type = "t2.micro"
  key_name = aws_key_pair.ranjani-keypair.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "webapp"
    }
  }
  user_data = filebase64("example.sh")
}

#ASG
resource "aws_autoscaling_group" "webapp-ASG" {
  #availability_zones = ["ap-south-1a","ap-south-1b"]
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2
  vpc_zone_identifier = [aws_subnet.webapp-public-subnet-1a.id,aws_subnet.webapp-public-subnet-1b.id]
  launch_template {
    id      = aws_launch_template.webapp-launch-template.id
    version = "$Latest"
  }
   target_group_arns = [aws_lb_target_group.webapp-TG-1.arn]
}
# ALB TG with ASG
 resource "aws_lb_target_group" "webapp-TG-1" {
   name     = "webapp-TG-1"
   port     = 80
   protocol = "HTTP"
   vpc_id   = aws_vpc.webapp-vpc.id
  }
# LB Listener with ASG
resource "aws_lb_listener" "webapp-listener-1" {
  load_balancer_arn = aws_lb.webapp-LB-1.arn
   port              = "80"
   protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp-TG-1.arn
  }
 }
#load balancer with ASG
 resource "aws_lb" "webapp-LB-1" {
  name               = "Webapp-LB-1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_ssh.id]
  subnets            = [aws_subnet.webapp-public-subnet-1a.id,aws_subnet.webapp-public-subnet-1b.id]
  tags = {
    Environment = "production"
   }
 }







