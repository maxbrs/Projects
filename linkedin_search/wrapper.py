#!/usr/bin/env python3
"""Linkedin search - wrapper

"""
import os
import sys

dir_path = os.path.dirname(os.path.realpath(__file__))
parent_dir_path = os.path.abspath(os.path.join(dir_path, os.pardir))
sys.path.insert(0, parent_dir_path)

from linkedin_search.account_scrapping import job as account_scrapping
from linkedin_search.prospect_search import job as prospect_search

if __name__ == '__main__':
    print('Start scrap the accounts ...')
    account_scrapping()
    print('Account scrapping DONE !')
    print('Start searching more info about the prospects ...')
    prospect_search()
    print('Prospect search DONE !')
