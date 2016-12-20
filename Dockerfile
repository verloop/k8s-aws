FROM python:2.7.12
# Roughly follows the kops aws tute
# https://github.com/kubernetes/kops/blob/ba3341ece8badb80a4ad84beac51f4e0f77fc614/docs/aws.md
ADD bin/ /root/bin

ENV PATH="/root/bin:$PATH"

ENV KOPS_STATE_STORE="s3://verloop-k8s-state-store"
RUN apt update && apt install vim --yes
WORKDIR /root
RUN pip install awscli
VOLUME /root/.aws
VOLUME /root/.kube
ENTRYPOINT /bin/bash