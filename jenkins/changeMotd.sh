#! /bin/bash

sed -e 's/Amazon Linux AMI/rispd Jenkins/' /etc/motd | sudo tee /etc/motd
