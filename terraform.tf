provider "aws"{
  region = "us-east-2"
}
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/24"

}
resource "aws_internet_gateway" "myvpcigw" {
    vpc_id = aws_vpc.myvpc.id
}

# attach the internet gateway my_vpc_igw into my_vpc.
resource "aws_route_table" "my_public_route_table" {
    vpc_id = aws_vpc.myvpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myvpcigw.id
    }
}
resource "aws_subnet" "newsubnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/25"

  tags = {
    Name = "newsubnet"
  }
}
resource "aws_subnet" "newsubnet2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.0.128/25"

  tags = {
    Name = "newsubnet2"
  }
}
resource "aws_route_table_association" "rt1" {
  subnet_id      = aws_subnet.newsubnet.id
  route_table_id = aws_route_table.my_public_route_table.id
}
resource "aws_route_table_association" "rt2" {
  subnet_id     = aws_subnet.newsubnet2.id
  route_table_id = aws_route_table.my_public_route_table.id
}

resource "aws_network_interface" "newNIC" {
  subnet_id   = aws_subnet.newsubnet.id


tags = {
    Name = "newNIC"
  }
}

resource "aws_instance" "newinstance" {
  ami= "ami-00dfe2c7ce89a450b" # us-west-2
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.newNIC.id
    device_index= 0
  }
}
resource "aws_lb" "LB" {
  name               = "LB-lb-tf"
  internal           = false
  load_balancer_type = "application"
  subnets            =[aws_subnet.newsubnet.id,aws_subnet.newsubnet2.id]

  enable_deletion_protection = true


}
resource "aws_lb_target_group" "tg" {
  name     = "tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id
}

resource "aws_lb_target_group_attachment" "tgA" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.newinstance.id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.LB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
