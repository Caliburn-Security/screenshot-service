#!/usr/bin/env python
# -*- coding utf-8 -*-

import json
import logging
import os
import boto3
from datetime import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

def handler(event, context):
    logger.debug("## ENVIRONMENT VARIABLES ##")
    logger.debug(os.environ)
    logger.debug("## EVENT ##")
    logger.debug(event)

    bucket_name = os.environ["s3_bucket"]
    logger.debug(f"bucket_name: {bucket_name}")

    logger.info("Extracting urls")

    urls = []
    if event["httpMethod"] == "GET":
        logger.debug(f"HTTP Method: GET")
        if event["queryStringParameters"]:
            try:
                urls.append(event["queryStringParameters"]["url"])
            except Exception as e:
                logger.error(e)
                return {
                    "statusCode": 500,
                    "body": json.dumps(e)
                }
        else:
            return {
                "statusCode": 400,
                "body": json.dumps("No URL provided...")
            }
    elif event["httpMethod"] == "POST":
        logger.debug("HTTP Method: POST")
        if event["body"]:
            try:
                body = json.loads(event["body"])
                if "urls" in body:
                    logger.info(f"{len(body['urls'])} urls submitted for processing")
                    urls = body["urls"]
                else:
                    urls.append(body["url"])
            except Exception as e:
                logger.error(e)
                return {
                    "statusCode": 500,
                    "body": json.dumps(e)
                }
        else:
            return {
                "statusCode": 400,
                "body": json.dumps("No URL provided...")
            }
    else:
        return {
            "statusCode": 405,
            "body": json.dumps(f"Invalid HTTP Method supplied: {event['httpMethod']}")
        }
    
    bucket_key = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
    logger.info(f"Creating S3 bucket: {bucket_name}/{bucket_key}")

    s3 = boto3.client("s3")
    s3.put_object(Bucket=bucket_name, Key=(f"{bucket_key}/"), ACL="public-read")
    data_test = b"TEST"
    #s3.upload_file(f"/tmp/{screenshot_title}.png", s3_bucket, f"{screenshot_title}.png", ExtraArgs={'ContentType': 'image/png', 'ACL': 'public-read'})
    s3.put_object(Bucket=bucket_name, Key=(f"{bucket_key}/test.txt"), Body=data_test, ACL="public-read", ContentType="text/plain")

    data = {
        "urls": urls,
        "bucket_name": bucket_name,
        "bucket_key": bucket_key
    }
    lambda_cli = boto3.client("lambda")
    lambda_cli.invoke(FunctionName=context.function_name, InvocationType="Event", Payload=json.dumps(data))

    response_body = {
        "message": "Folder successfully created in S3 bucket for URLs. Retrieving screenshots now!",
        "s3_path": f"https://{bucket_name}.s3.amazonaws.com/{bucket_key}/"
    }

    return {
        "statusCode": 200,
        "body": json.dumps(response_body)
    }
