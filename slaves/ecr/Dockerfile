FROM amazonlinux

RUN yum install -y java-1.8.0-openjdk wget
COPY agent.jar /home/ec2-user/
COPY entrypoint.sh /
RUN chmod 755 /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
