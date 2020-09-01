#!/usr/bin/env python
# -*- coding utf-8 -*-

# TODO: Add logging and cloudwatch
# TODO: Leverage lambda layers so that I can supply the chrome executables without pulling each time

import json
import logging
from urllib.parse import urlparse, unquote # TODO: Can I use urllib3?
from selenium import webdriver
from datetime import datetime
import os
from shutil import copyfile
import boto3
import stat
import urllib.request
import tldextract

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

def configure_binaries():
    """Copy the binary files from the lambda layer to /tmp and make them executable"""
    copyfile("/opt/chromedriver", "/tmp/chromedriver")
    copyfile("/opt/headless-chromium", "/tmp/headless-chromium")

    os.chmod("/tmp/chromedriver", 755)
    os.chmod("/tmp/headless-chromium", 755)

def get_screenshot(url, s3_bucket, screenshot_title = None): 
#   TODO                                                   : Validate the best way to handle options
#   TODO                                                   : Allow specifying the port...?
#   TODO                                                   : Allow for a list of URLs for screenshotting...maybe split this function as a separate function, and the handler calls?  Step function?
    
    configure_binaries()

    chrome_options = webdriver.ChromeOptions()
    chrome_options.add_argument('--headless')
    chrome_options.add_argument("disable-infobars")
    chrome_options.add_argument("enable-automation")
    
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-gpu')
    chrome_options.add_argument('--window-size=1280x1696')
    chrome_options.add_argument('--user-data-dir=/tmp/user-data')
    chrome_options.add_argument('--hide-scrollbars')
    chrome_options.add_argument('--enable-logging')
    chrome_options.add_argument('--log-level=0')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--v=99')
    chrome_options.add_argument('--single-process')
    chrome_options.add_argument('--data-path=/tmp/data-path')
    chrome_options.add_argument('--ignore-certificate-errors')
    chrome_options.add_argument('--homedir=/tmp')
    chrome_options.add_argument('--disk-cache-dir=/tmp/cache-dir')
    chrome_options.add_argument(
        'user-agent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36')
    chrome_options.binary_location = "/tmp/headless-chromium"

    if screenshot_title is None: 
        ext = tldextract.extract(url)
        domain = f"{''.join(ext[:2])}:{urlparse(url).port}.{ext[2]}"
        screenshot_title = f"{domain}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"
    logger.debug(f"Screenshot title: {screenshot_title}")

    with webdriver.Chrome(chrome_options=chrome_options, executable_path="/tmp/chromedriver", service_log_path="/tmp/selenium.log") as driver: # TODO: Is the with loop the best approach?
        driver.set_window_size(1024, 768)
        
        logger.info(f"Obtaining screenshot for {url}")
        driver.get(url)     
        
        driver.save_screenshot(f"/tmp/{screenshot_title}.png") # TODO: Delete the screenshot after
        logger.info(f"Uploading /tmp/{screenshot_title}.png to S3 bucket {s3_bucket}/{screenshot_title}.png")
        s3 = boto3.client("s3")
        s3.upload_file(f"/tmp/{screenshot_title}.png", s3_bucket, f"{screenshot_title}.png", ExtraArgs={'ContentType': 'image/png', 'ACL': 'public-read'})
    return f"https://{s3_bucket}.s3.amazonaws.com/{screenshot_title}.png"

def handler(event, context): 
    logger.debug("## ENVIRONMENT VARIABLES ##")
    logger.debug(os.environ)
    logger.debug("## EVENT ##")
    logger.debug(event)

    bucket_name = os.environ["s3_bucket"]
    logger.debug(f"bucket_name: {bucket_name}")

    logger.info("Validating url")  
    urls = None
    if "url" in event: # Using this for testing in lambda.
            try:
                url = event["url"]
            except Exception as e:
                logger.error(e)
                raise e
    else:
        if event["httpMethod"] == "GET":
            if event["queryStringParameters"]:
                try:
                    url = event["queryStringParameters"]["url"]
                except Exception as e:
                    logger.error(e)
                    raise e
            else:
                return {
                    "statusCode": 400,
                    "body": json.dumps("No URL provided...")
                }
        elif event["httpMethod"] == "POST":
            if event["body"]:
                try:
                    body = json.loads(event["body"])
                    if "urls" in body and "url" not in body:
                        logger.info(f"{len(body['urls'])} urls submitted for processing")
                        urls = body["urls"]
                        body.pop("urls", None)
                        logger.debug(f"nullcheck: {'urls' in body}")
                    else:
                        url = body["url"]
                except Exception as e:
                    logger.error(e)
                    raise e
            else:
                return {
                    "statusCode": 400,
                    "body": json.dumps("No URL provided...")
                }
        else:
            return {
                "statusCode": 405,
                "body": json.dumps(f"Invalid HTTP Method {event['httpMethod']} supplied")
            }

        if urls is not None:
            logger.debug("urls is not None")
            logger.debug(f"context.function_name: {context.function_name}")
            # Recurse!!
            for url in urls:            
                logger.info(f"Processing url: {url}")
                lambda_cli = boto3.client("lambda")
                body = json.loads(event["body"])
                body["url"] = url
                event["body"] = json.dumps(body)
                lambda_cli.invoke(FunctionName=context.function_name, InvocationType="Event", Payload=json.dumps(event))
            response_body = {
                "message": f"{len(urls)} urls will be scanned"
            }
            return {
                "statusCode": 200,
                "body": json.dumps(response_body)
            }
        else:
            logger.debug("Processing URL")
            return process_url(url, bucket_name)

def process_url(url, bucket_name):
    logger.info(f"Decoding {url}")
    url = unquote(url)

    logger.info(f"Parsing {url}")
    try: 
        parsed_url = urlparse(url)
        if parsed_url.scheme != "http" and parsed_url.scheme != "https":
            logger.info("No valid scheme found, defaulting to http://")
            parsed_url = urlparse(f"http://{url}")
        if parsed_url.port is None:
            if parsed_url.scheme == "http":
                parsed_url = urlparse(f"{parsed_url.geturl()}:80")
            elif parsed_url.scheme == "https":
                parsed_url = urlparse(f"{parsed_url.geturl()}:443")

    except Exception as e: 
        logger.error(e)
        raise e
    
    logger.info("Getting screenshot")
    try: 
        screenshot_url = get_screenshot(parsed_url.geturl(), bucket_name) # TODO: Variable!
    except Exception as e:  
        logger.error(e)
        raise e

    response_body = {
        "message": f"Successfully captured screenshot of {parsed_url.geturl()}",
        "screenshot_url": screenshot_url
    }

    return {
        "statusCode": 200,
        "body"      : json.dumps(response_body)
    }