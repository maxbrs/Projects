"""Linkedin search - account scrapping

"""
import time
import pandas as pd
from bs4 import BeautifulSoup
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.wait import WebDriverWait
from tqdm import tqdm

from linkedin_search.tools import load_parameters, init_driver, \
    load_or_init_df, linkedin_login, smooth_scroll_down, click_next_page, \
    save_df, shut_driver, clean_html_text

LINKEDIN_SOURCE_URL = 'https://www.linkedin.com'
LINKEDIN_SALES_SOURCE_URL = LINKEDIN_SOURCE_URL + '/sales'


def wait_new_page_loading(driver):
    WebDriverWait(driver, 10).\
        until(EC.presence_of_element_located((By.CLASS_NAME,
                                              'search-results__result-list')))


def search_soup(page_source, df, page):
    soup = BeautifulSoup(page_source, 'lxml')
    for result_item in soup.select('li.search-results__result-item'):
        for name_element in result_item.select('dt.result-lockup__name a'):
            company = clean_html_text(name_element.text)
            linkedin_url = LINKEDIN_SOURCE_URL + name_element['href']

        details = []
        for info in result_item.select('li.result-lockup__misc-item'):
            details.append(info.text)

        idx = int(linkedin_url
                  .lstrip(f'{LINKEDIN_SALES_SOURCE_URL}/company/')
                  .split('?')[0])
        if len(details) == 3:
            df = df.append(pd.Series({'company': company,
                                      'linkedin_url': linkedin_url,
                                      'sector': details[0],
                                      'size': details[1],
                                      'location': details[2],
                                      'page': page},
                                     name=idx))
        else:
            df = df.append(pd.Series({'company': company,
                                      'linkedin_url': linkedin_url,
                                      'page': page},
                                     name=idx))
    return df[~df.index.duplicated(keep='first')]


def job():
    parameters = load_parameters()
    for selection_name, selection_url in parameters['URLs'].items():
        driver = init_driver()
        linkedin_login(driver, selection_url, parameters['login'])
        account_df = load_or_init_df(parameters['account_file_name'],
                                     selection_name)
        with tqdm(total=parameters['pages_to_scrap']) as pbar:
            for i in range(parameters['pages_to_scrap']):
                wait_new_page_loading(driver)
                smooth_scroll_down(driver)
                time.sleep(1)
                account_df = search_soup(driver.page_source,
                                         account_df,
                                         i + 1)
                click_next_page(driver)
                pbar.update()

                if not account_df.empty \
                    and (pbar.n != 0 and pbar.n % 5 == 0) \
                    or pbar.n == pbar.total:
                    save_df(account_df,
                            parameters['account_file_name'],
                            selection_name)

        shut_driver(driver)


if __name__ == '__main__':
    job()
