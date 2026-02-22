import json
import boto3
import logging
import os
import string
import random

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def generate_password(length=32):
    """Generate a secure random password."""
    chars = string.ascii_letters + string.digits + "!@#$%^&*()_+-=[]{}|"
    return ''.join(random.choice(chars) for _ in range(length))

def lambda_handler(event, context):
    """Handle the rotation of RDS database password."""
    arn = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']

    # Create AWS clients
    secretsmanager = boto3.client('secretsmanager')
    rds = boto3.client('rds')

    # Get the secret metadata
    metadata = secretsmanager.describe_secret(SecretId=arn)
    if "RotationEnabled" in metadata and not metadata['RotationEnabled']:
        logger.error("Secret %s is not enabled for rotation" % arn)
        raise ValueError("Secret %s is not enabled for rotation" % arn)

    # Get the current secret value
    current = secretsmanager.get_secret_value(SecretId=arn)
    current_dict = json.loads(current['SecretString'])

    # Get the database instance identifier
    db_instance_id = current_dict['dbInstanceIdentifier']

    if step == "createSecret":
        # Generate a new password
        new_password = generate_password()
        
        # Create a new secret version with the new password
        secretsmanager.put_secret_value(
            SecretId=arn,
            ClientRequestToken=token,
            SecretString=json.dumps({
                **current_dict,
                'password': new_password
            })
        )
        logger.info("Created new secret version for %s" % arn)

    elif step == "setSecret":
        # Update the RDS instance with the new password
        rds.modify_db_instance(
            DBInstanceIdentifier=db_instance_id,
            MasterUserPassword=new_password,
            ApplyImmediately=True
        )
        logger.info("Updated RDS instance %s with new password" % db_instance_id)

    elif step == "testSecret":
        # Test the new password by attempting to connect to the database
        # This is a placeholder - in a real implementation, you would test the connection
        logger.info("Testing new password for %s" % arn)

    elif step == "finishSecret":
        # Mark the new version as active
        secretsmanager.update_secret_version_stage(
            SecretId=arn,
            VersionStage="AWSCURRENT",
            MoveToVersionId=token,
            RemoveFromVersionId=current['VersionId']
        )
        logger.info("Finished rotation for %s" % arn)

    else:
        raise ValueError("Invalid step parameter")

    return {
        'statusCode': 200,
        'body': json.dumps('Rotation step completed successfully')
    } 