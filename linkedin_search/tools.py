"""Linkedin search - general tools

"""
import time

import pandas as pd
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.wait import WebDriverWait

from yaml import load, FullLoader


def load_parameters():
    file = 'parameters.yml'
    with open(file, 'r') as yml_file:
        parameters = load(yml_file, Loader=FullLoader)
    return parameters


def init_driver():
    profile = webdriver.FirefoxProfile()
    profile.set_preference('intl.accept_languages', 'en-GB')
    return webdriver.Firefox(firefox_profile=profile)


def linkedin_login(driver, url, login):
    driver.get(url)
    driver.implicitly_wait(10)
    element = driver.find_element_by_class_name('authentication-iframe')
    driver.get(element.get_attribute('src'))
    WebDriverWait(driver, 10)\
        .until(EC.presence_of_element_located((By.ID, 'username')))
    driver.find_element_by_xpath("//input[@id='username']")\
        .send_keys(login['username'])
    driver.find_element_by_xpath("//input[@id='password']")\
        .send_keys(login['password'])
    driver.find_element_by_xpath("//button[@type='submit']").click()
    driver.implicitly_wait(3)
    driver.get(url)


def load_df(file_name, selection_name=None):
    if selection_name:
        file_name = file_name.replace('{placeholder}', selection_name) \
            if '{placeholder}' in file_name else file_name
    return pd.read_csv(file_name, index_col=0)


def load_or_init_df(file_name, selection_name=None):
    try:
        df = load_df(file_name, selection_name)
        print(f'File {file_name} read !')
    except FileNotFoundError:
        print(f'File {file_name} not found !\nNew dataframe initialised.')
        df = pd.DataFrame()
    return df


def clean_html_text(text):
    return text.lstrip().rstrip().replace('\n', '')


def smooth_scroll_down(driver, scroll_pause_time=.25, n=250):
    total_height = int(driver
                       .execute_script('return document.body.scrollHeight'))
    for i in range(1, total_height, n):
        driver.execute_script(f'window.scrollTo(0, {i});')
        time.sleep(scroll_pause_time)


def click_next_page(driver):
    next_page_class_name = 'search-results__pagination-next-button'
    next_page = driver.find_element_by_class_name(next_page_class_name)
    next_page.click()
    time.sleep(1)


def shut_driver(driver):
    driver.close()


def save_df(df, file_name, selection_name=None):
    if selection_name:
        file_name = file_name.replace('{placeholder}', selection_name) \
            if '{placeholder}' in file_name else file_name
    df.to_csv(file_name)
    print(f'File {file_name} saved !')
