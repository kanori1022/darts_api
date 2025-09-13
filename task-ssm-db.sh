#! /bin/bash

# ログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.ap-northeast-1.amazonaws.com
# タスクIDの取得
TASK_ID=$(aws ecs list-tasks \
    --cluster darts_api \
    --service-name darts_api_task_definition-service-69mkaqef \
    --query "taskArns[0]" \
    --output text | cut -d "/" -f3)

if [ -z "$TASK_ID" ]; then
    echo "Error: Task ID not found"
    exit 1
fi

# コンテナランタイムIDの取得（apiコンテナ）
CONTAINER_RUNTIME_ID=$(aws ecs describe-tasks \
    --cluster darts_api \
    --tasks $TASK_ID \
    --query "tasks[0].containers[?name=='api'].runtimeId" \
    --output text)

if [ -z "$CONTAINER_RUNTIME_ID" ]; then
    echo "Error: Container runtime ID not found"
    exit 1
fi

echo "Task ID: $TASK_ID"
echo "Container Runtime ID: $CONTAINER_RUNTIME_ID"
echo "Port: 13306"

# SSMセッションの開始
aws ssm start-session \
    --target ecs:darts_api_${TASK_ID}_${CONTAINER_RUNTIME_ID} \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters "{\"host\":[\"darts-database.cv0i6mcgq0wu.ap-northeast-1.rds.amazonaws.com\"],\"portNumber\":[\"3306\"],\"localPortNumber\":[\"13306\"]}"


