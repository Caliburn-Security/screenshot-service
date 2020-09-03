import requests
import os
import logging
import json
from urllib.parse import urlparse, unquote

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

def handler(event, context):
    logger.debug("## ENVIRONMENT VARIABLES ##")
    logger.debug(os.environ)
    logger.debug("## EVENT ##")
    logger.debug(event)

    if event["queryStringParameters"] is None or "url" not in event["queryStringParameters"]:
        resp = {
            "message": "Please submit a valid URL or FQDN"
        }
        return {
            "statusCode": 400,
            "body": json.dumps(resp)
        }

    url = get_url(event["queryStringParameters"]["url"])

    warnings = []
    resp = {}
    headers = {
        "x-api-key": os.environ["apigw_key"]
    }

    r = requests.get(f"https://api.caliburnsecurity.com/screenshot?url={url.geturl()}", headers=headers)
    data = r.json()

    if r.status_code != 200:
        warnings.append(data["message"])
    else:
        resp["screenshot_url"] = data["screenshot_url"]

    r = requests.get(f"https://api.caliburnsecurity.com/dns?FQDN={url.netloc}", headers=headers)
    data = r.json()

    if r.status_code != 200:
        warnings.append(data["message"])
    else:
        resp["dns_records"] = data["dns_records"]
        if len(data["warnings"]) > 0:
            warnings.extend(data["warnings"])
    
    return {
        "statusCode": 200,
        "body": json.dumps(resp)
    }
    
def get_url(url, https_default=os.environ["https_default"]):
    logger.info(f"Decoding {url}")
    url = unquote(url)

    logger.info(f"Parsing {url}")
    try:
        url = urlparse(url)
        if url.scheme != "http" and url.scheme != "https":
            url = urlparse(f"https://{url}") if https_default == True else urlparse(f"http://{url}")
        if url.port is None:
            url = urlparse(f"{url.geturl()}:443") if https_default == True else urlparse(f"{url.geturl():80}")
    except Exception as e:
        logger.error(e)
        return {
            "statusCode": "400",
            "message": "Invalid URL provided",
            "error": str(e)
        }
    return url

if __name__ == "__main__":
    main()