resource "aws_security_group" "sg_inst" {
  description       = "security group for instance"
  vpc_id            = var.vpc_id
  dynamic "ingress"{
      for_each      = [for r in var.inbound_rules:{
        f_port      = r.from_port
        t_port      = r.to_port
        cidr        = r.cidr
        protocol    = r.protocol
      }
    ]
    content {
        from_port   = ingress.value.f_port
        to_port     = ingress.value.t_port
        protocol    = ingress.value.protocol
        cidr_blocks = [ingress.value.cidr]
    }
  }

  dynamic "egress"{
     for_each       = [for r in var.outbound_rules:{
        f_port      = r.from_port
        t_port      = r.to_port
        cidr        = r.cidr
        protocol    = r.protocol
      }
    ]
    content {
        from_port   = egress.value.f_port
        to_port     = egress.value.t_port
        protocol    = egress.value.protocol
        cidr_blocks = [egress.value.cidr]
    } 
  }
}

resource "aws_eip" "app" {
  count = var.module_type == "app" ? 1 : 0

  instance = "${aws_instance.ec2_instance.id}"
  vpc      = true
}

resource "aws_instance" "ec2_instance" {
  instance_type   = var.instance_type
  ami             = var.instance_ami
  subnet_id       = var.instance_subnet
  key_name        = var.instance_key_name
  security_groups = [aws_security_group.sg_inst.id]
  iam_instance_profile = var.module_type == "app" ? var.instance_profile : null

    tags = {
    Name = var.identifier
  }

}

resource "aws_ebs_volume" "cold_volume" {
  count = var.volume_size != "" ? 1 : 0
  
  availability_zone = var.availability_zone
  size              = var.volume_size
  type              = "sc1"

  tags = {
    Name = var.identifier
  }
}

resource "aws_volume_attachment" "device_attach" {
  count = var.volume_size != "" ? 1 : 0

  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.cold_volume[0].id
  instance_id = aws_instance.ec2_instance.id
}