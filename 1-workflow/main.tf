resource "aws_instance" "vm" {
  ami           = "ami-00ca570c1b6d79f36"
  instance_type = "t3.micro"
  key_name      = "linux"
  tags = {
    Name = "webserver"
    }
}