# AWS リソース停止・起動スクリプト

このスクリプトは、AWSの以下のリソースを自動で停止・起動します：

- **ECS**: タスク数を0にする（停止時）、1に戻す（起動時）
- **RDS**: インスタンスを一時停止する（停止時）、起動する（起動時）
- **VPC Endpoint**: 利用可能なアベイラビリティゾーンを2つ外す（停止時）、復元する（起動時）

## 前提条件

1. **AWS CLI** がインストールされていること
2. **AWS認証情報** が設定されていること（`aws configure` で設定済み）
3. **適切なIAM権限** を持っていること：
   - ECS: `ecs:UpdateService`, `ecs:DescribeServices`
   - RDS: `rds:StopDBInstance`, `rds:StartDBInstance`, `rds:DescribeDBInstances`
   - EC2: `ec2:ModifyVpcEndpoint`, `ec2:DescribeVpcEndpoints`, `ec2:DescribeAvailabilityZones`

## 使用方法

### 1. スクリプトの実行権限を付与

```bash
chmod +x aws-stop-start.sh
```

### 2. スクリプトの実行

#### リソースを停止する
```bash
./aws-stop-start.sh stop
```

#### リソースを起動する
```bash
./aws-stop-start.sh start
```

#### 現在の状態を確認する
```bash
./aws-stop-start.sh status
```

## 設定値

スクリプト内の以下の値を環境に合わせて変更してください：

```bash
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
```

## 動作詳細

### 停止処理 (`stop`)

1. **ECS**: `desired-count` を 0 に設定
2. **RDS**: インスタンスを一時停止（`available` → `stopped`）
3. **VPC Endpoint**: 指定された5つのVPC Endpointで、サブネットが2つより多い場合、2つを残して他を削除

### 起動処理 (`start`)

1. **ECS**: `desired-count` を 1 に設定
2. **RDS**: インスタンスを起動（`stopped` → `available`）
3. **VPC Endpoint**: 指定された5つのVPC Endpointで、利用可能なすべてのサブネットを復元

### 状態確認 (`status`)

現在の各リソースの状態を表示：
- ECS の desired count
- RDS の状態
- 指定された各 VPC Endpoint の状態とサブネット数

## 完全自動化の特徴

このスクリプトは**完全自動化**されており、実行後に手動操作は一切不要です：

1. **待機処理**: 各リソースの状態変更完了を自動で待機
2. **状態確認**: 操作前に現在の状態を確認し、不要な操作をスキップ
3. **エラーハンドリング**: リソースが見つからない場合も適切に処理
4. **タイムアウト**: 各操作に適切なタイムアウトを設定（ECS: 5分、RDS: 10分、VPC Endpoint: 5分）

## 注意事項

1. **RDS**: 停止から起動まで数分かかる場合があります（自動で待機します）
2. **ECS**: タスクの起動・停止にも時間がかかる場合があります（自動で待機します）
3. **VPC Endpoint**: サブネットの変更は自動で完了まで待機します
4. スクリプト実行前に、必要なAWS認証情報が設定されていることを確認してください
5. 本番環境で実行する前に、テスト環境で動作確認することを推奨します
6. **実行時間**: 停止処理は約5-10分、起動処理は約5-15分程度かかります

## トラブルシューティング

### AWS認証エラー
```
ERROR: AWS credentials not configured. Please run 'aws configure' first.
```
→ `aws configure` で認証情報を設定してください

### 権限エラー
```
An error occurred (AccessDenied) when calling the UpdateService operation
```
→ IAMユーザーに適切な権限が付与されているか確認してください

### リソースが見つからない
```
An error occurred (DBInstanceNotFound) when calling the DescribeDBInstances operation
```
→ スクリプト内の設定値（クラスター名、サービス名、RDSインスタンス名など）が正しいか確認してください

## ログ出力

スクリプトは実行時のログをタイムスタンプ付きで出力します：
```
[2024-01-15 10:30:00] Starting AWS resources shutdown...
[2024-01-15 10:30:01] Stopping ECS service...
[2024-01-15 10:30:02] Current desired count: 1
[2024-01-15 10:30:03] ECS service stopped successfully
```
