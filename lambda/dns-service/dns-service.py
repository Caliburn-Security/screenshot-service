import logging
import os
import dns.resolver
import json
from ast import literal_eval
import sys

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

def handler(event, context):
    logger.debug("## ENVIRONMENT VARIABLES ##")
    logger.debug(os.environ)
    logger.debug("## EVENT ##")
    logger.debug(event)   
    logger.debug(len(event)) 
    logger.debug(event["queryStringParameters"])

    if event["queryStringParameters"] is None or "FQDN" not in event["queryStringParaemters"]:
        resp = {
            "message": "Please submit a valid FQDN"
        }
        return {
            "statusCode": 400,
            "body": json.dumps(resp)
        }

    RESOLVER_TIMEOUT = int(os.environ["RESOLVER_TIMEOUT"])
    RESOLVER_LIFETIME = int(os.environ["RESOLVER_LIFETIME"])
    DNS_RECORD_TYPES = literal_eval(os.environ["DNS_RECORD_TYPES"]) if event["queryStringParameters"] is not None and "recordTypes" not in event["queryStringParameters"] else event["queryStringParameters"]["recordTypes"].split(",") # Not sure why this is necessary, I am passing the array in...


    FQDN = event["queryStringParameters"]["FQDN"]

    logger.info(f"Obtaining DNS records from {FQDN}")
    resolver = dns.resolver.Resolver()
    logger.debug(f"Setting DNS timeout to {RESOLVER_TIMEOUT} seconds")
    resolver.timeout = 1
    logger.debug(f"Setting the query lifetime to {RESOLVER_LIFETIME} seconds")
    resolver.lifetime = 1

    dns_records = {}
    warnings = []

    for record in DNS_RECORD_TYPES:
        logger.debug(f"Record: {record}")
        try:
            answer = resolver.query(FQDN, record)
            for rdata in answer:
                if record.lower() not in dns_records.keys():
                    dns_records[record.lower()] = []
                dns_records[record.lower()].append(rdata.to_text())
        except dns.exception.DNSException as e:
            logger.warning(e)
            warnings.append(str(e))

    resp = {
        "message": f"Successfully performed DNS lookups against {FQDN}",
        "dns_records": dns_records,
        "warnings": warnings
    }

    logger.info(dns_records)

    return {
        "statusCode": 200,
        "body": json.dumps(resp)
    }