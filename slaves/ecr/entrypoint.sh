#! /bin/bash

java -jar /home/ec2-user/agent.jar -jnlpUrl http://$JENKINS_IP:8080/computer/slave$SLAVE_NUMBER/slave-agent.jnlp -secret $SECRET_KEY -workDir "/home/ec2-user"
tail -f /dev/null
