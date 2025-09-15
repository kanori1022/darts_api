#!/bin/bash

# ECRにログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.ap-northeast-1.amazonaws.com

# ECRにpush
docker build -t latest . --no-cache
docker tag latest 248612013161.dkr.ecr.ap-northeast-1.amazonaws.com/darts_api:latest
docker push 248612013161.dkr.ecr.ap-northeast-1.amazonaws.com/darts_api:latest

# 1. 新しいリビジョンを作成
# https://248612013161-c7jjfyp2.ap-northeast-1.console.aws.amazon.com/ecs/v2/task-definitions/darts_api_task_definition?status=ACTIVE&region=ap-northeast-1
# で新しいリビジョンを作成

# 2. サービスを更新
# https://248612013161-c7jjfyp2.ap-northeast-1.console.aws.amazon.com/ecs/v2/clusters/darts_api/services/darts_api_task_definition-service-69mkaqef/update?region=ap-northeast-1
# でサービスを更新(新しい数字にする)
