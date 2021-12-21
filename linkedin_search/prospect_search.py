"""Linkedin search - prospect search

"""
import time
from collections import defaultdict

import pandas as pd
from bs4 import BeautifulSoup
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.wait import WebDriverWait
from tqdm import tqdm

from linkedin_search.tools import load_parameters, load_df, init_driver, \
    linkedin_login, smooth_scroll_down, load_or_init_df, save_df, \
    clean_html_text, shut_driver

LINKEDIN_SOURCE_URL = 'https://www.linkedin.com'


def wait_new_page_loading(driver):
    WebDriverWait(driver, 10)\
        .until(EC.presence_of_element_located((By.CLASS_NAME, 'meta-links')))


def wait_end_loading(driver):
    WebDriverWait(driver, 10) \
        .until(EC.presence_of_element_located((By.CLASS_NAME,
                                               'recommended-leads-container')))


def get_company_url(soup):
    element = soup.find('div', attrs={'class': 'meta-links'})
    return element.find('a')['href']


def get_prospect_info(soup, company_id):
    data = defaultdict(list)
    df_idx = []
    for element in soup.findAll('div',
                                attrs={'class': 'profile-container'}):
        name = element.find('a', attrs={'class': 'title'})
        prospect_name = clean_html_text(name.text)
        data['name'].append(prospect_name)
        data['linkedin_url'].append(LINKEDIN_SOURCE_URL + name['href'])
        role = element.find('dd', attrs={'class': 'subtitle'})
        role = clean_html_text(role.text)
        data['role'].append(role)
        details = element.findAll('dd', attrs={'class': 'muted-copy'})
        details = [clean_html_text(d.text) for d in details]
        if len(details) != 2:
            print()
        data['seniority'].append(details[0])
        data['location'].append(details[1])
        df_idx.append(f'{company_id}_{hash(prospect_name)}_{hash(role)}')
    data['company_id'] = [company_id] * len(df_idx)
    return pd.DataFrame(data, index=df_idx)


def search_soup(page_source, company_id):
    soup = BeautifulSoup(page_source, 'lxml')
    return get_company_url(soup), get_prospect_info(soup, company_id)


def job():
    parameters = load_parameters()
    prospect_df = load_or_init_df(parameters['prospect_file_name'])
    for selection_name, selection_url in parameters['URLs'].items():
        driver = init_driver()
        linkedin_login(driver, selection_url, parameters['login'])
        account_df = load_df(parameters['account_file_name'], selection_name)
        account_df['company_url'] = None
        with tqdm(total=len(account_df)) as pbar:
            for company_id, row in account_df.iterrows():
                driver.get(row['linkedin_url'])
                wait_new_page_loading(driver)
                smooth_scroll_down(driver)
                time.sleep(1)
                wait_end_loading(driver)
                company_url, prospect_info = search_soup(driver.page_source,
                                                         company_id)
                account_df.loc[company_id, 'company_url'] = company_url
                prospect_df = prospect_df.append(prospect_info)
                pbar.update()

                if pbar.n != 0 and pbar.n % 5 == 0 or pbar.n == pbar.total:
                    if not account_df.empty:
                        save_df(account_df,
                                parameters['account_file_name'],
                                selection_name)
                    if not prospect_df.empty:
                        save_df(prospect_df,
                                parameters['prospect_file_name'])

        shut_driver(driver)


if __name__ == '__main__':
    job()
