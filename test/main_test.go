package test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformBasicExample(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"project":     "test-project",
			"environment": "test",
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test S3 Bucket
	bucketID := terraform.Output(t, terraformOptions, "state_bucket_name")
	aws.AssertS3BucketExists(t, "us-west-2", bucketID)

	// Test DynamoDB Table
	tableName := terraform.Output(t, terraformOptions, "state_lock_table_name")
	aws.AssertDynamoDBTableExists(t, "us-west-2", tableName)

	// Test KMS Key
	keyID := terraform.Output(t, terraformOptions, "kms_key_arn")
	aws.AssertKmsKeyExists(t, "us-west-2", keyID)

	// Test VPC Endpoints
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	endpoints := aws.GetVpcEndpoints(t, "us-west-2", vpcID)
	assert.Greater(t, len(endpoints), 0)

	// Test Security Groups
	securityGroupID := terraform.Output(t, terraformOptions, "security_group_id")
	aws.AssertSecurityGroupExists(t, "us-west-2", securityGroupID)

	// Test CloudWatch Log Groups
	logGroupName := terraform.Output(t, terraformOptions, "log_group_name")
	aws.AssertCloudWatchLogGroupExists(t, "us-west-2", logGroupName)

	// Test IAM Roles
	roleName := terraform.Output(t, terraformOptions, "iam_role_name")
	aws.AssertIAMRoleExists(t, "us-west-2", roleName)

	// Test Secrets Manager
	secretARN := terraform.Output(t, terraformOptions, "secret_arn")
	aws.AssertSecretsManagerSecretExists(t, "us-west-2", secretARN)

	// Smoke Test - Verify Services
	verifyServices(t, terraformOptions)
}

func verifyServices(t *testing.T, terraformOptions *terraform.Options) {
	// Add service-specific smoke tests here
	// Example: Verify RDS instance is accessible
	// Example: Verify S3 bucket can be accessed
	// Example: Verify CloudWatch metrics are being collected
} 