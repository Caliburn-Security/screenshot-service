# coding: utf-8

import sys
from time import sleep

import click
import dns.resolver
 

@click.group()
def main():
    pass


@main.command()
@click.argument('domain')
@click.option('--record-type', default='NS')
@click.option('--interval', default=30, type=int)
def check(domain, record_type, interval):
    while True:
        print('### checking %s %s record ###' % (domain, record_type))

        try:
            nameservers = dns.resolver.query(domain, record_type)
        except dns.resolver.NoAnswer:
            print('No answer yet')
            sleep(interval)
            continue
        except KeyboardInterrupt:
            print('Done')
            sys.exit()

        for data in nameservers:
            print(data)

        sleep(interval)
