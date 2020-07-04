#!/usr/bin/env python
# -*- coding utf-8 -*-

# TODO: Add logging and cloudwatch
# TODO: Leverage lambda layers so that I can supply the chrome executables without pulling each time

import json
import logging
from urllib.parse import urlparse, unquote # TODO: Can I use urllib3?
from selenium import webdriver
import time
import os
from shutil import copyfile
import boto3
import stat
import urllib.request
from zipfile import ZipFile
from tld import get_tld

#HEADLESS_CHROME = "https://github.com/adieuadieu/serverless-chrome/releases/download/v1.0.0-54/stable-headless-chromium-amazonlinux-2017-03.zip"
#CHROMEDRIVER    = "https://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip"

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

def configure_binaries():
    copyfile("/opt/chromedriver", "/tmp/chromedriver")
    copyfile("/opt/headless-chromium", "/tmp/headless-chromium")

    os.chmod("/tmp/chromedriver", 755)
    os.chmod("/tmp/headless-chromium", 755)

def get_screenshot(url, s3_bucket, screenshot_title = None): 
#   TODO                                                   : Extract domain from URL and add to screenshot file title
#   TODO                                                   : Validate the best way to handle options
#   TODO                                                   : Allow specifying the port...?
#   TODO                                                   : Allow for a list of URLs for screenshotting...
    
    configure_binaries()

    chrome_options = webdriver.ChromeOptions()
    chrome_options.add_argument('--headless')
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

    with webdriver.Chrome(chrome_options=chrome_options, executable_path="/tmp/chromedriver", service_log_path="/tmp/selenium.log") as driver: # TODO: Is the with loop the best approach?
        driver.set_window_size(1024, 768)
        
        logger.info(f"Obtaining screenshot for {url}")
        driver.get(url)
        if screenshot_title is None: 
            screenshot_title = f"{get_tld(url)}_{time.time()}"
        driver.save_screenshot(f"/tmp/{screenshot_title}.png") # TODO: Delete the screenshot after
        logger.info(f"Uploading /tmp/{screenshot_title}.png to S3 bucket {s3_bucket}/{screenshot_title}.png")
        s3 = boto3.client("s3")
        s3.upload_file(f"/tmp/{screenshot_title}.png", s3_bucket, f"{screenshot_title}.png")

def handler(event, context): 
    logger.debug(f"Event: {event}")
    logger.info("Validating url")  

    bucket_name = os.environ["s3_bucket"]

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
            "statusCode": 400,
            "body": json.dumps(f"Invalid HTTP Method {event['httpMethod']} supplied")
        }


        
    
    logger.info(f"Decoding {url}")
    url = unquote(url)

    logger.info(f"Parsing {url}")
    try: 
        parsed_url = urlparse(url)
        if parsed_url.scheme != "http" and parsed_url.scheme != "https":
            url = f"http://{url}"

    except Exception as e: 
        logger.error(e)
        raise e
    
    logger.info("Getting screenshot")
    try: 
        get_screenshot(url, bucket_name) # TODO: Variable!
    except Exception as e:  
        logger.error(e)
        raise e

    return {
        "statusCode": 200,
        "body"      : json.dumps(f"Susscessfully captured screenshot of {url}")
    }