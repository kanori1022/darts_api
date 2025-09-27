#!/bin/bash

# AWS リソース停止・起動スクリプト
# 使用方法: ./aws-stop-start.sh [stop|start]

set -e

# 設定値
ECS_CLUSTER="darts_api"
ECS_SERVICE="darts_api_task_definition-service-69mkaqef"
RDS_INSTANCE="darts-database"
RDS_ENDPOINT="darts-database.cv0i6mcgq0wu.ap-northeast-1.rds.amazonaws.com"
REGION="ap-northeast-1"

# VPC Endpoint IDs
VPC_ENDPOINT_IDS=(
    "vpce-01646d24dc6a1f093"
    "vpce-0f0fa46a77fb30f1f"
    "vpce-0cd9bc95a4d4e0d38"
    "vpce-0a387cb5382c23017"
    "vpce-0f4b2db3b3a505ca6"
)

# ログ関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# エラー処理
error_exit() {
    log "ERROR: $1"
    exit 1
}

# 待機処理関数
wait_for_vpc_endpoint_modification() {
    local endpoint_id=$1
    local max_wait=300  # 5分
    local wait_time=0
    
    log "Waiting for VPC Endpoint $endpoint_id modification to complete..."
    
    while [ $wait_time -lt $max_wait ]; do
        local status=$(aws ec2 describe-vpc-endpoints \
            --vpc-endpoint-ids $endpoint_id \
            --query "VpcEndpoints[0].State" \
            --output text \
            --no-cli-pager 2>/dev/null || echo "NotFound")
        
        if [ "$status" = "available" ]; then
            log "VPC Endpoint $endpoint_id modification completed"
            return 0
        fi
        
        log "VPC Endpoint $endpoint_id status: $status, waiting..."
        sleep 10
        wait_time=$((wait_time + 10))
    done
    
    log "WARNING: VPC Endpoint $endpoint_id modification timeout after ${max_wait}s"
    return 1
}

wait_for_rds_state() {
    local instance_id=$1
    local target_state=$2
    local max_wait=600  # 10分
    local wait_time=0
    
    log "Waiting for RDS instance $instance_id to reach state: $target_state"
    
    while [ $wait_time -lt $max_wait ]; do
        local status=$(aws rds describe-db-instances \
            --db-instance-identifier $instance_id \
            --query "DBInstances[0].DBInstanceStatus" \
            --output text \
            --no-cli-pager 2>/dev/null || echo "NotFound")
        
        if [ "$status" = "$target_state" ]; then
            log "RDS instance $instance_id reached state: $target_state"
            return 0
        fi
        
        log "RDS instance $instance_id status: $status, waiting for $target_state..."
        sleep 30
        wait_time=$((wait_time + 30))
    done
    
    log "WARNING: RDS instance $instance_id timeout waiting for $target_state after ${max_wait}s"
    return 1
}

wait_for_ecs_service_stable() {
    local cluster=$1
    local service=$2
    local max_wait=300  # 5分
    local wait_time=0
    
    log "Waiting for ECS service $service to stabilize..."
    
    while [ $wait_time -lt $max_wait ]; do
        local running_count=$(aws ecs describe-services \
            --cluster $cluster \
            --services $service \
            --query "services[0].runningCount" \
            --output text \
            --no-cli-pager)
        
        local desired_count=$(aws ecs describe-services \
            --cluster $cluster \
            --services $service \
            --query "services[0].desiredCount" \
            --output text \
            --no-cli-pager)
        
        if [ "$running_count" = "$desired_count" ]; then
            log "ECS service $service stabilized (running: $running_count, desired: $desired_count)"
            return 0
        fi
        
        log "ECS service $service running: $running_count, desired: $desired_count, waiting..."
        sleep 15
        wait_time=$((wait_time + 15))
    done
    
    log "WARNING: ECS service $service stabilization timeout after ${max_wait}s"
    return 1
}

# AWS CLI がインストールされているかチェック
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        error_exit "AWS CLI is not installed. Please install AWS CLI first."
    fi
}

# AWS認証チェック
check_aws_auth() {
    if ! aws sts get-caller-identity --no-cli-pager &> /dev/null; then
        error_exit "AWS credentials not configured. Please run 'aws configure' first."
    fi
}

# ECSタスクを0にする
stop_ecs_service() {
    log "Stopping ECS service..."
    
    # 現在のdesired countを取得
    DESIRED_COUNT=$(aws ecs describe-services \
        --cluster $ECS_CLUSTER \
        --services $ECS_SERVICE \
        --query "services[0].desiredCount" \
        --output text \
        --no-cli-pager)
    
    log "Current desired count: $DESIRED_COUNT"
    
    if [ "$DESIRED_COUNT" = "0" ]; then
        log "ECS service is already stopped (desired count: 0)"
        return 0
    fi
    
    # desired countを0に設定
    log "Setting desired count to 0 for service $ECS_SERVICE"
    UPDATE_RESULT=$(aws ecs update-service \
        --cluster $ECS_CLUSTER \
        --service $ECS_SERVICE \
        --desired-count 0 \
        --no-cli-pager \
        --output json 2>&1)
    
    if [ $? -eq 0 ]; then
        log "ECS service update initiated successfully"
        
        # サービスが安定するまで待機
        wait_for_ecs_service_stable $ECS_CLUSTER $ECS_SERVICE
        
        # 最終確認
        FINAL_COUNT=$(aws ecs describe-services \
            --cluster $ECS_CLUSTER \
            --services $ECS_SERVICE \
            --query "services[0].desiredCount" \
            --output text \
            --no-cli-pager)
        
        if [ "$FINAL_COUNT" = "0" ]; then
            log "ECS service stopped successfully (final desired count: $FINAL_COUNT)"
        else
            log "WARNING: ECS service desired count is $FINAL_COUNT, expected 0"
        fi
    else
        log "ERROR: Failed to update ECS service"
        log "Error details: $UPDATE_RESULT"
        return 1
    fi
}

# ECSタスクを元の数に戻す
start_ecs_service() {
    log "Starting ECS service..."
    
    # 現在のdesired countを確認
    DESIRED_COUNT=$(aws ecs describe-services \
        --cluster $ECS_CLUSTER \
        --services $ECS_SERVICE \
        --query "services[0].desiredCount" \
        --output text \
        --no-cli-pager)
    
    log "Current desired count: $DESIRED_COUNT"
    
    if [ "$DESIRED_COUNT" != "0" ]; then
        log "ECS service is already running (desired count: $DESIRED_COUNT)"
        return 0
    fi
    
    # desired countを1に設定（元の設定に応じて調整）
    log "Setting desired count to 1 for service $ECS_SERVICE"
    UPDATE_RESULT=$(aws ecs update-service \
        --cluster $ECS_CLUSTER \
        --service $ECS_SERVICE \
        --desired-count 1 \
        --no-cli-pager \
        --output json 2>&1)
    
    if [ $? -eq 0 ]; then
        log "ECS service update initiated successfully"
        
        # サービスが安定するまで待機
        wait_for_ecs_service_stable $ECS_CLUSTER $ECS_SERVICE
        
        # 最終確認
        FINAL_COUNT=$(aws ecs describe-services \
            --cluster $ECS_CLUSTER \
            --services $ECS_SERVICE \
            --query "services[0].desiredCount" \
            --output text \
            --no-cli-pager)
        
        if [ "$FINAL_COUNT" = "1" ]; then
            log "ECS service started successfully (final desired count: $FINAL_COUNT)"
        else
            log "WARNING: ECS service desired count is $FINAL_COUNT, expected 1"
        fi
    else
        log "ERROR: Failed to update ECS service"
        log "Error details: $UPDATE_RESULT"
        return 1
    fi
}

# RDSを一時停止
stop_rds_instance() {
    log "Stopping RDS instance..."
    
    # インスタンスの現在の状態を確認
    STATUS=$(aws rds describe-db-instances \
        --db-instance-identifier $RDS_INSTANCE \
        --query "DBInstances[0].DBInstanceStatus" \
        --output text \
        --no-cli-pager 2>/dev/null || echo "NotFound")
    
    log "Current RDS status: $STATUS"
    
    if [ "$STATUS" = "NotFound" ]; then
        log "RDS instance $RDS_INSTANCE not found, skipping"
        return 0
    fi
    
    if [ "$STATUS" = "stopped" ]; then
        log "RDS instance is already stopped"
        return 0
    fi
    
    if [ "$STATUS" = "available" ]; then
        aws rds stop-db-instance \
            --db-instance-identifier $RDS_INSTANCE \
            --no-cli-pager \
            --output table
        log "RDS instance stop initiated"
        
        # 停止完了まで待機
        wait_for_rds_state $RDS_INSTANCE "stopped"
    else
        log "RDS instance is not in 'available' state. Current status: $STATUS"
    fi
}

# RDSを起動
start_rds_instance() {
    log "Starting RDS instance..."
    
    # インスタンスの現在の状態を確認
    STATUS=$(aws rds describe-db-instances \
        --db-instance-identifier $RDS_INSTANCE \
        --query "DBInstances[0].DBInstanceStatus" \
        --output text \
        --no-cli-pager 2>/dev/null || echo "NotFound")
    
    log "Current RDS status: $STATUS"
    
    if [ "$STATUS" = "NotFound" ]; then
        log "RDS instance $RDS_INSTANCE not found, skipping"
        return 0
    fi
    
    if [ "$STATUS" = "available" ]; then
        log "RDS instance is already running"
        return 0
    fi
    
    if [ "$STATUS" = "stopped" ]; then
        aws rds start-db-instance \
            --db-instance-identifier $RDS_INSTANCE \
            --no-cli-pager \
            --output table
        log "RDS instance start initiated"
        
        # 起動完了まで待機
        wait_for_rds_state $RDS_INSTANCE "available"
    else
        log "RDS instance is not in 'stopped' state. Current status: $STATUS"
    fi
}

# VPC Endpointの停止処理
stop_vpc_endpoints() {
    log "Stopping VPC Endpoints by removing availability zones..."
    
    for ENDPOINT in "${VPC_ENDPOINT_IDS[@]}"; do
        log "Processing VPC Endpoint: $ENDPOINT"
        
        # エンドポイントの存在確認と詳細情報を取得
        ENDPOINT_INFO=$(aws ec2 describe-vpc-endpoints \
            --vpc-endpoint-ids $ENDPOINT \
            --query "VpcEndpoints[0]" \
            --output json --no-cli-pager 2>/dev/null)
        
        if [ $? -ne 0 ] || [ -z "$ENDPOINT_INFO" ] || [ "$ENDPOINT_INFO" = "null" ]; then
            log "VPC Endpoint $ENDPOINT not found, skipping"
            continue
        fi
        
        # 状態を取得（jqの代わりに直接クエリを使用）
        STATUS=$(aws ec2 describe-vpc-endpoints \
            --vpc-endpoint-ids $ENDPOINT \
            --query "VpcEndpoints[0].State" \
            --output text --no-cli-pager 2>/dev/null || echo "NotFound")
        
        VPC_ID=$(aws ec2 describe-vpc-endpoints \
            --vpc-endpoint-ids $ENDPOINT \
            --query "VpcEndpoints[0].VpcId" \
            --output text --no-cli-pager 2>/dev/null || echo "NotFound")
        
        ENDPOINT_TYPE=$(aws ec2 describe-vpc-endpoints \
            --vpc-endpoint-ids $ENDPOINT \
            --query "VpcEndpoints[0].VpcEndpointType" \
            --output text --no-cli-pager 2>/dev/null || echo "NotFound")
        
        log "VPC Endpoint $ENDPOINT details:"
        log "  Status: $STATUS"
        log "  VPC ID: $VPC_ID"
        log "  Type: $ENDPOINT_TYPE"
        
        # Gateway型の場合はサブネット操作不要
        if [ "$ENDPOINT_TYPE" = "Gateway" ]; then
            log "Gateway type endpoint $ENDPOINT - no subnet modification needed"
            continue
        fi
        
        # Interface型でavailable状態でない場合は待機
        if [ "$STATUS" != "available" ]; then
            log "VPC Endpoint $ENDPOINT is not available (status: $STATUS), waiting for it to become available..."
            
            # available状態になるまで待機
            local max_wait=300
            local wait_time=0
            while [ $wait_time -lt $max_wait ] && [ "$STATUS" != "available" ]; do
                sleep 10
                wait_time=$((wait_time + 10))
                STATUS=$(aws ec2 describe-vpc-endpoints \
                    --vpc-endpoint-ids $ENDPOINT \
                    --query "VpcEndpoints[0].State" \
                    --output text --no-cli-pager 2>/dev/null || echo "NotFound")
                log "Waiting for $ENDPOINT to become available... (status: $STATUS)"
            done
            
            if [ "$STATUS" != "available" ]; then
                log "WARNING: VPC Endpoint $ENDPOINT did not become available within timeout, skipping"
                continue
            fi
        fi
        
        # 現在のサブネットを取得
        CURRENT_SUBNETS=$(aws ec2 describe-vpc-endpoints \
            --vpc-endpoint-ids $ENDPOINT \
            --query "VpcEndpoints[0].SubnetIds" \
            --output text --no-cli-pager)
        
        log "Current Subnet IDs for $ENDPOINT: $CURRENT_SUBNETS"
        
        # サブネット配列に変換
        SUBNET_ARRAY=($CURRENT_SUBNETS)
        SUBNET_COUNT=${#SUBNET_ARRAY[@]}
        
        log "Current subnet count: $SUBNET_COUNT"
        
        # 停止処理では、すべてのサブネットを削除してエンドポイントを実質停止
        if [ $SUBNET_COUNT -gt 0 ]; then
            log "Endpoint $ENDPOINT has $SUBNET_COUNT subnets, removing all subnets to stop the endpoint"
            
            # すべてのサブネットを削除
            for SUBNET in "${SUBNET_ARRAY[@]}"; do
                log "Removing Subnet $SUBNET from endpoint $ENDPOINT"
                REMOVE_RESULT=$(aws ec2 modify-vpc-endpoint \
                    --vpc-endpoint-id $ENDPOINT \
                    --remove-subnet-ids $SUBNET \
                    --no-cli-pager \
                    --output json 2>&1)
                
                if [ $? -eq 0 ]; then
                    log "Successfully removed Subnet $SUBNET from endpoint $ENDPOINT"
                    # 変更が完了するまで待機
                    wait_for_vpc_endpoint_modification $ENDPOINT
                else
                    log "ERROR: Failed to remove Subnet $SUBNET from endpoint $ENDPOINT"
                    log "Error details: $REMOVE_RESULT"
                fi
            done
        else
            log "Endpoint $ENDPOINT already has 0 subnets - already stopped"
        fi
        
        # 最終確認
        FINAL_SUBNETS=$(aws ec2 describe-vpc-endpoints \
            --vpc-endpoint-ids $ENDPOINT \
            --query "VpcEndpoints[0].SubnetIds" \
            --output text --no-cli-pager)
        FINAL_COUNT=$(echo "$FINAL_SUBNETS" | wc -w)
        log "Final subnet count for $ENDPOINT: $FINAL_COUNT"
    done
    
    log "VPC Endpoints processing completed"
}

# VPC Endpointのアベイラビリティゾーンを復元
start_vpc_endpoints() {
    log "Starting VPC Endpoints by restoring availability zones..."
    
    for ENDPOINT in "${VPC_ENDPOINT_IDS[@]}"; do
        log "Processing VPC Endpoint: $ENDPOINT"
        
        # エンドポイントの存在確認と詳細情報を取得
        ENDPOINT_INFO=$(aws ec2 describe-vpc-endpoints \
            --vpc-endpoint-ids $ENDPOINT \
            --query "VpcEndpoints[0]" \
            --output json --no-cli-pager 2>/dev/null)
        
        if [ $? -ne 0 ] || [ -z "$ENDPOINT_INFO" ] || [ "$ENDPOINT_INFO" = "null" ]; then
            log "VPC Endpoint $ENDPOINT not found, skipping"
            continue
        fi
        
        # 状態を取得（jqの代わりに直接クエリを使用）
        STATUS=$(aws ec2 describe-vpc-endpoints \
            --vpc-endpoint-ids $ENDPOINT \
            --query "VpcEndpoints[0].State" \
            --output text --no-cli-pager 2>/dev/null || echo "NotFound")
        
        VPC_ID=$(aws ec2 describe-vpc-endpoints \
            --vpc-endpoint-ids $ENDPOINT \
            --query "VpcEndpoints[0].VpcId" \
            --output text --no-cli-pager 2>/dev/null || echo "NotFound")
        
        ENDPOINT_TYPE=$(aws ec2 describe-vpc-endpoints \
            --vpc-endpoint-ids $ENDPOINT \
            --query "VpcEndpoints[0].VpcEndpointType" \
            --output text --no-cli-pager 2>/dev/null || echo "NotFound")
        
        log "VPC Endpoint $ENDPOINT details:"
        log "  Status: $STATUS"
        log "  VPC ID: $VPC_ID"
        log "  Type: $ENDPOINT_TYPE"
        
        # Gateway型の場合はサブネット操作不要
        if [ "$ENDPOINT_TYPE" = "Gateway" ]; then
            log "Gateway type endpoint $ENDPOINT - no subnet modification needed"
            continue
        fi
        
        # Interface型でavailable状態でない場合は待機
        if [ "$STATUS" != "available" ]; then
            log "VPC Endpoint $ENDPOINT is not available (status: $STATUS), waiting for it to become available..."
            
            # available状態になるまで待機
            local max_wait=300
            local wait_time=0
            while [ $wait_time -lt $max_wait ] && [ "$STATUS" != "available" ]; do
                sleep 10
                wait_time=$((wait_time + 10))
                STATUS=$(aws ec2 describe-vpc-endpoints \
                    --vpc-endpoint-ids $ENDPOINT \
                    --query "VpcEndpoints[0].State" \
                    --output text --no-cli-pager 2>/dev/null || echo "NotFound")
                log "Waiting for $ENDPOINT to become available... (status: $STATUS)"
            done
            
            if [ "$STATUS" != "available" ]; then
                log "WARNING: VPC Endpoint $ENDPOINT did not become available within timeout, skipping"
                continue
            fi
        fi
        
        # 現在のサブネットを取得
        CURRENT_SUBNETS=$(aws ec2 describe-vpc-endpoints \
            --vpc-endpoint-ids $ENDPOINT \
            --query "VpcEndpoints[0].SubnetIds" \
            --output text --no-cli-pager)
        
        log "Current Subnet IDs for $ENDPOINT: $CURRENT_SUBNETS"
        
        # VPCのすべてのサブネットを取得
        ALL_SUBNETS=$(aws ec2 describe-subnets \
            --filters "Name=vpc-id,Values=$VPC_ID" \
            --query "Subnets[].SubnetId" \
            --output text --no-cli-pager)
        
        log "Available Subnets in VPC $VPC_ID: $ALL_SUBNETS"
        
        # 現在のサブネット数とVPCの全サブネット数を比較
        CURRENT_ARRAY=($CURRENT_SUBNETS)
        ALL_ARRAY=($ALL_SUBNETS)
        
        log "Current subnet count: ${#CURRENT_ARRAY[@]}, Total available subnets: ${#ALL_ARRAY[@]}"
        
        # 不足しているサブネットを特定（アベイラビリティゾーンを考慮）
        MISSING_SUBNETS=()
        USED_AZS=()
        
        # 現在使用中のアベイラビリティゾーンを取得
        for SUBNET in "${CURRENT_ARRAY[@]}"; do
            if [ -n "$SUBNET" ]; then
                AZ=$(aws ec2 describe-subnets \
                    --subnet-ids $SUBNET \
                    --query "Subnets[0].AvailabilityZone" \
                    --output text --no-cli-pager 2>/dev/null || echo "")
                if [ -n "$AZ" ]; then
                    USED_AZS+=("$AZ")
                fi
            fi
        done
        
        log "Currently used AZs: ${USED_AZS[*]}"
        
        # 異なるAZのサブネットのみを追加対象にする
        for SUBNET in "${ALL_ARRAY[@]}"; do
            if [[ ! " ${CURRENT_ARRAY[@]} " =~ " ${SUBNET} " ]]; then
                # サブネットのアベイラビリティゾーンを取得
                AZ=$(aws ec2 describe-subnets \
                    --subnet-ids $SUBNET \
                    --query "Subnets[0].AvailabilityZone" \
                    --output text --no-cli-pager 2>/dev/null || echo "")
                
                if [ -n "$AZ" ]; then
                    # 既に使用されているAZでない場合のみ追加対象にする
                    if [[ ! " ${USED_AZS[@]} " =~ " ${AZ} " ]]; then
                        MISSING_SUBNETS+=("$SUBNET")
                        USED_AZS+=("$AZ")
                        log "Subnet $SUBNET (AZ: $AZ) will be added"
                    else
                        log "Skipping subnet $SUBNET (AZ: $AZ) - AZ already in use"
                    fi
                else
                    log "WARNING: Could not determine AZ for subnet $SUBNET"
                fi
            fi
        done
        
        if [ ${#MISSING_SUBNETS[@]} -gt 0 ]; then
            log "Adding subnets for $ENDPOINT: ${MISSING_SUBNETS[*]}"
            
            # 不足しているサブネットを追加
            for SUBNET in "${MISSING_SUBNETS[@]}"; do
                log "Adding Subnet $SUBNET to endpoint $ENDPOINT"
                ADD_RESULT=$(aws ec2 modify-vpc-endpoint \
                    --vpc-endpoint-id $ENDPOINT \
                    --add-subnet-ids $SUBNET \
                    --no-cli-pager \
                    --output json 2>&1)
                
                if [ $? -eq 0 ]; then
                    log "Successfully added Subnet $SUBNET to endpoint $ENDPOINT"
                    # 変更が完了するまで待機
                    wait_for_vpc_endpoint_modification $ENDPOINT
                else
                    log "ERROR: Failed to add Subnet $SUBNET to endpoint $ENDPOINT"
                    log "Error details: $ADD_RESULT"
                    
                    # AZ制約エラーの場合は、そのAZをスキップして続行
                    if [[ "$ADD_RESULT" == *"DuplicateSubnetsInSameZone"* ]]; then
                        log "AZ constraint error - skipping this subnet and continuing"
                    fi
                fi
            done
        else
            log "No missing subnets for endpoint $ENDPOINT - all subnets are already present"
        fi
        
        # 最終確認
        FINAL_SUBNETS=$(aws ec2 describe-vpc-endpoints \
            --vpc-endpoint-ids $ENDPOINT \
            --query "VpcEndpoints[0].SubnetIds" \
            --output text --no-cli-pager)
        FINAL_COUNT=$(echo "$FINAL_SUBNETS" | wc -w)
        log "Final subnet count for $ENDPOINT: $FINAL_COUNT"
    done
    
    log "VPC Endpoints restoration completed"
}

# リソースの状態確認
check_status() {
    log "Checking current status of all resources..."
    
    # ECS status
    DESIRED_COUNT=$(aws ecs describe-services \
        --cluster $ECS_CLUSTER \
        --services $ECS_SERVICE \
        --query "services[0].desiredCount" \
        --output text --no-cli-pager)
    log "ECS desired count: $DESIRED_COUNT"
    
    # RDS status
    RDS_STATUS=$(aws rds describe-db-instances \
        --db-instance-identifier $RDS_INSTANCE \
        --query "DBInstances[0].DBInstanceStatus" \
        --output text 2>/dev/null || echo "Not found")
    log "RDS status: $RDS_STATUS"
    
    # VPC Endpoints status
    log "VPC Endpoints status:"
    for ENDPOINT in "${VPC_ENDPOINT_IDS[@]}"; do
        STATUS=$(aws ec2 describe-vpc-endpoints \
            --vpc-endpoint-ids $ENDPOINT \
            --query "VpcEndpoints[0].State" \
            --output text --no-cli-pager 2>/dev/null || echo "NotFound")
        SUBNET_COUNT=$(aws ec2 describe-vpc-endpoints \
            --vpc-endpoint-ids $ENDPOINT \
            --query "length(VpcEndpoints[0].SubnetIds)" \
            --output text 2>/dev/null || echo "0")
        log "  $ENDPOINT: $STATUS (Subnets: $SUBNET_COUNT)"
    done
}

# メイン処理
main() {
    if [ $# -eq 0 ]; then
        echo "Usage: $0 [stop|start|status]"
        echo "  stop   - Stop all AWS resources (ECS=0, RDS=paused, VPC Endpoints=reduce AZs)"
        echo "  start  - Start all AWS resources (ECS=1, RDS=start, VPC Endpoints=restore AZs)"
        echo "  status - Check current status of all resources"
        exit 1
    fi
    
    ACTION=$1
    
    # 事前チェック
    check_aws_cli
    check_aws_auth
    
    case $ACTION in
        "stop")
            log "Starting AWS resources shutdown..."
            stop_ecs_service
            stop_rds_instance
            stop_vpc_endpoints
            log "AWS resources shutdown completed"
            ;;
        "start")
            log "Starting AWS resources startup..."
            start_vpc_endpoints
            start_rds_instance
            start_ecs_service
            log "AWS resources startup completed"
            ;;
        "status")
            check_status
            ;;
        *)
            error_exit "Invalid action: $ACTION. Use 'stop', 'start', or 'status'"
            ;;
    esac
}

# スクリプト実行
main "$@"
