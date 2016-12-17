FROM python:2.7.12
# Roughly follows the kops aws tute
# https://github.com/kubernetes/kops/blob/ba3341ece8badb80a4ad84beac51f4e0f77fc614/docs/aws.md
ADD sources/kops-linux-amd64 /usr/local/bin/kops
ADD sources/kubectl /usr/local/bin/kubectl
ADD sources/jq-linux64 /usr/local/bin/jq
# RUN apt-get update && apt-get install vim --yes
WORKDIR /root
RUN pip install awscli
VOLUME /root/.aws
VOLUME /root/.kube
ENTRYPOINT /bin/bash