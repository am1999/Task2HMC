provider "aws" {
    region = "ap-south-1"
    profile = "terrapro"
}

resource "aws_key_pair" "task2" {
  key_name   = "task2"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAo07CnzIo//QCHS8lfuiAAkZnM/Os/unHK6dyZFbv9g6PlZ8BqKbjg3p9bH6pTt0pN6zFYhQU+QNQghULihzfmiXyL22NwrpD93BMHCJMBDBXzZ8TiljyxOu20yV4yLjnj7kQ8JB2gZOhlv5Fg3jBjRrpIhMKD7gXKIkgKwqpt6dtwbCD5qfJ91zl/zDS8OYeYsFFjXHRw5uMnGt1COFj4E8Yr2zzO1afJ1afLIyxdKt2LUzCWATUNsl8GdiIcNYMzuQnecBAeE1lE+Ljh06k8PU4YmlNBaOsXqmZqG/EsvrOKoh4ula774zWrv+s8X3CJnzl218dMeVsENFfg0LFqQ== rsa-key-20200730"
}

resource "aws_vpc" "vpctwo"{
    
    cidr_block = "192.168.0.0/16"
    instance_tenancy = "default"
    tags = {
        Name = "vpctwo"
    }
}

resource "aws_subnet" "subnettwo" {
    
    vpc_id = "${aws_vpc.vpctwo.id}"
    cidr_block = "192.168.0.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "ap-south-1a"
    tags = {
        Name = "subnettwo"
    }
}

resource "aws_security_group" "sgtask2" {
  name        = "sgtask2"
  description = "Allow HTTP inbound traffic"
  vpc_id      = "${aws_vpc.vpctwo.id}"

ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks=["0.0.0.0/0"]
  }
ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks=["0.0.0.0/0"]
  }
egress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks=["0.0.0.0/0"]
  }
egress {
    description = "HTTP from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks=["0.0.0.0/0"]
  }
 tags = {
    Name = "sgtask2"
  }
}

resource "aws_efs_file_system" "efs_task" {
                
            creation_token = "efs_task"
                tags = {
                  Name = "efs_task"
                }
}

resource "aws_efs_mount_target" "efsmount" {
            file_system_id = "${aws_efs_file_system.efs_task.id}"
            subnet_id = "${aws_subnet.subnettwo.id}"
            security_groups = [aws_security_group.sgtask2.id]
}

resource "aws_internet_gateway" "gateway2"{
    vpc_id = "${aws_vpc.vpctwo.id}"
    tags = {
        Name = "gateway2"  
    }
}

resource "aws_route_table" "rt_two" {
    vpc_id = "${aws_vpc.vpctwo.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gateway2.id}"
    }
    tags = {
        Name = "rt_two"
    }
}

resource "aws_route_table_association" "assoc" {
    subnet_id = "${aws_subnet.subnettwo.id}"
    route_table_id = "${aws_route_table.rt_two.id}"
}

resource "aws_instance" "inst" {
        ami             =  "ami-052c08d70def0ac62"
        instance_type   =  "t2.micro"
        key_name        =  "task2"
        subnet_id     = "${aws_subnet.subnettwo.id}"
        security_groups = ["${aws_security_group.sgtask2.id}"]

    connection {
        type     = "ssh"
        user     = "ec2-user"
        private_key = file("C:/Users/DELL/Desktop/Terraform/task2p.pem")
        host     = aws_instance.inst.public_ip
    }

    provisioner "remote-exec" {
        inline = [
            "sudo yum install amazon-efs-utils -y",
            "sudo yum install httpd  php git -y",
            "sudo systemctl restart httpd",
            "sudo systemctl enable httpd",
            "sudo setenforce 0",
            "sudo yum -y install nfs-utils"
        ]
    }

    tags = {
        Name = "inst"
    }
}

resource "null_resource" "mount"  {
    depends_on = [aws_efs_mount_target.efsmount]
        connection {
            type     = "ssh"
            user     = "ec2-user"
            private_key = file("C:/Users/DELL/Desktop/Terraform/task2p.pem")
            host     = aws_instance.inst.public_ip
        }
        provisioner "remote-exec" {
            inline = [
                "sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_file_system.efs_task.id}.efs.ap-south-1.amazonaws.com:/ /var/www/html",
                "sudo rm -rf /var/www/html/*",
                "sudo git  clone  https://github.com/am1999/Task2HMC.git  /var/www/html/",
                "sudo sed -i 's/url /${aws_cloudfront_distribution.myfront.domain_name}/g' /var/www/html/task2.html"
            ]
        }
}

resource "null_resource" "git_copy"  {
      provisioner "local-exec" {
        command = "git clone https://github.com/am1999/Task2HMC.git C:/Users/DELL/Desktop/Terraform/task2git"
        }
    }

resource "null_resource" "inst_ip"  {
        provisioner "local-exec" {
            command = "echo  ${aws_instance.inst.public_ip} > public_ip.txt"
          }
      }


resource "aws_s3_bucket" "anki21" {
        bucket = "anki21"
        acl    = "private"

        tags = {
          Name        = "anki21"
        }
}
locals {
    s3_origin_id = "S3storage"
}


resource "aws_s3_bucket_object" "object" {
    bucket = "${aws_s3_bucket.anki21.id}"
    key    = "task2"
    source = "C:/Users/DELL/Desktop/Terraform/task2git/EFSimg.jpg"
    acl    = "public-read"
}

resource "aws_cloudfront_distribution" "myfront" {
    origin {
        domain_name = "${aws_s3_bucket.anki21.bucket_regional_domain_name}"
        origin_id   = "${local.s3_origin_id}"

            custom_origin_config {
              http_port = 80
              https_port = 80
              origin_protocol_policy = "match-viewer"
              origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
            }
    }
    enabled = true
    default_cache_behavior {

            allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST",
                                "PUT"]
            cached_methods   = ["GET", "HEAD"]
            target_origin_id = "${local.s3_origin_id}"

            forwarded_values {

                query_string = false
                cookies {
                      forward = "none"
                }
            }

            viewer_protocol_policy = "allow-all"
            min_ttl                = 0
            default_ttl            = 3600
            max_ttl                = 86400

    }
        
    restrictions {
                geo_restriction {
                 restriction_type = "none"
                }
    }
       
    viewer_certificate {
          cloudfront_default_certificate = true
    }
}


