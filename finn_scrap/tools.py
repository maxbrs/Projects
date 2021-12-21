"""Finn scrap - general tools

"""
import math
import re
import time
from random import randint

import pandas as pd
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.wait import WebDriverWait
from unidecode import unidecode

from yaml import load, FullLoader

PATH = './finn_scrap/'
FINN_URL = 'https://www.finn.no'
NB_ADDS_PER_PAGE = 50
DETAILS_CLEANUP_MAPPING = \
    {'Fellesgjeld': lambda x: int(x.replace(' ', '').replace(' kr', '')),
     'Pris med fellesgjeld': lambda x: int(x.replace(' ', '')
                                           .replace(' kr', '')),
     'Omkostninger': lambda x: int(x.replace(' ', '').replace(' kr', '')),
     'Totalpris': lambda x: int(x.replace(' ', '').replace(' kr', '')),
     'Felleskost/mnd.': lambda x: int(x.replace(' ', '')
                                      .replace(' kr', '')),
     'Formuesverdi': lambda x: int(x.replace(' ', '').replace(' kr', '')),
     'Fellesformue': lambda x: int(x.replace(' ', '').replace(' kr', '')),
     'Festeavgift': lambda x: int(x.replace(' ', '').replace(' kr', '')),
     # 'prisantydning': lambda x: int(x.replace(' ', '')
     #                                .replace(' kr', '')
     #                                .replace(' ', '')
     #                                .replace('\n', '')),
     'Primærrom': lambda x: int(x.replace(' m²', '')),
     'Bruksareal': lambda x: int(x.replace(' m²', '')),
     'Bruttoareal': lambda x: int(x.replace(' m²', '')),
     'Tomteareal': lambda x: int(re.sub('[\(\[].*?[\)\]]', '', x)
                                 .replace(' m²', '')
                                 .replace(' ', '')),
     'Rom': lambda x: int(x),
     'Soverom': lambda x: int(x),
     'Etasje': lambda x: int(x),
     'Byggeår': lambda x: int(x),
     'Energimerking': lambda x: x.strip(),
     'Boligselgerforsikring': lambda x: x == 'Ja'}


def load_parameters():
    file = 'parameters.yml'
    with open(PATH + file, 'r') as yml_file:
        parameters = load(yml_file, Loader=FullLoader)
    return parameters


def init_driver(selection_url=None):
    profile = webdriver.FirefoxProfile()
    profile.set_preference('intl.accept_languages', 'en-GB')
    driver = webdriver.Firefox(firefox_profile=profile)
    if selection_url is not None:
        driver.get(selection_url)
    return driver


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


def search_nb_pages(page_source):
    soup = BeautifulSoup(page_source, 'lxml')
    nb_adds = int(unidecode(soup.find_all('span',
                                          class_='u-strong')[-1].string)
                  .replace(' ', ''))
    return math.ceil(nb_adds / NB_ADDS_PER_PAGE)


def wait_page_loading(driver):
    WebDriverWait(driver, 5).\
        until(EC.presence_of_element_located((By.CLASS_NAME,
                                              'ads--cards')))


def clean_price(price):
    if price:
        if ' ' in price:
            price = int(price.split(' ')[0])
        elif 'kr' in price:
            price = int(price.split('-')[0].replace('kr', ''))
    return price


def scrap_search_page(page_source, df):
    soup = BeautifulSoup(page_source, 'lxml')
    for item in soup.select('article.ads__unit'):
        element = item.find('a', class_='ads__unit__link')
        size_price = [x.text for x in
                      item.find('div',
                                class_='ads__unit__content__keys').contents]
        if len(size_price) == 2:
            size, price = size_price
        else:
            size, price = None, None
            for val in size_price:
                if val.endswith('m²'):
                    size = val
                elif val.endswith('kr'):
                    price = val
        price = str(price.replace(' ', '')) \
            if price is not None else None
        info = {
            'pic_url': item.find('img', class_='img-format__img').attrs['src'],
            'url': element.attrs['href'],
            'title': element.string,
            'address': item.find('div',
                                 class_='ads__unit__content__details')
            .next.text,
            'size': size,
            'price': clean_price(price)
        }
        info['url'] = FINN_URL + info['url']\
            if not info['url'].startswith('https://')\
            else info['url']
        try:
            info.update({n.split(':')[0]: n.split(':')[1].replace(' ', '')
                        .replace(' ', '') for n in
                         item.find('div', class_='ads__unit__content__list')
                        .next.split(' • ')})
            if 'Totalpris' in info.keys():
                info['Totalpris'] = clean_price(info['Totalpris'])
        except:
            pass
        idx = int(info['url'].split('&')[0].split('finnkode=')[-1])
        df = df.append(pd.Series(info, name=idx))

    return df[~df.index.duplicated(keep='last')]


def extract_neighborhood_and_price(soup):
    neighborhood_and_price = [str(tag.contents[0].string)
                              .replace('\n', '')
                              .replace('  ', '') for tag
                              in soup.find_all('span', class_='u-t3')][:2]
    try:
        neighborhood, price = neighborhood_and_price
        price = int(price.replace('\n', '')
                    .replace(' ', '')
                    .replace(' kr', ''))
        return neighborhood, price
    except ValueError:
        if len(neighborhood_and_price) == 0:
            return None, None
        elif len(neighborhood_and_price) == 1:
            if neighborhood_and_price[0].endswith(' kr'):
                price = neighborhood_and_price[0]
                neighborhood = None
            else:
                price = None
                neighborhood = neighborhood_and_price[0]
            return neighborhood, price
    raise ValueError('Problem with neighborhood_and_price!')


def search_soup(page):
    info = dict()
    try:
        neighborhood, price = extract_neighborhood_and_price(page)
        info.update({'neighborhood': neighborhood,
                     'address': page.find('p', class_='u-caption').get_text(),
                     'prisantydning': price})

        description = page.find('div', id='collapsableTextContent')
        description = '\n'.join([txt.strip() for txt
                                 in description.get_text().split('\n')
                                 if (txt or '').strip()])
        info.update({'description': description})
    except (ValueError, AttributeError):
        pass

    try:
        details = [[txt.strip() for txt in item.get_text().split('\n')
                    if txt.strip()]
                   for item in page.find_all('dl', 'definition-list')]
        details += [[txt.strip() for txt
                     in element.contents[1].get_text().split('\n')
                     if txt.strip()] for element
                    in page.find('div', 'panel u-text-left').children
                    if element.name == 'table']
    except (ValueError, AttributeError):
        details = []

    for details_chunk in details:
        if len(details_chunk) == 0:
            continue
        elif len(details_chunk) % 2 != 0:
            print(f'Problem with details : {details_chunk}')
            continue

        additional_info = {}

        try:
            for idx in range(0, len(details_chunk), 2):
                key = details_chunk[idx]
                val = details_chunk[idx + 1].replace('.', '')
                f = DETAILS_CLEANUP_MAPPING.get(key, lambda x: x)
                additional_info[key] = f(val)
        except (ValueError, AttributeError):
            pass

        info.update(additional_info)

    try:
        list_images = [page.parent.contents[1].attrs for page in
                       page.find_all('p', class_='image-carousel__caption')]
        list_images = [img.get('src', None) or img.get('data-src', None)
                       for img in list_images]
        info.update({'image_urls': list_images})
    except (ValueError, AttributeError):
        pass

    return info


def scrap_individual_page(housing_info, driver, pbar=None):
    driver.get(housing_info['url'])

    try:
        WebDriverWait(driver, 3)\
            .until(EC.presence_of_element_located((By.ID,
                                                   'collapsableTextContent')))
        new_info = search_soup(BeautifulSoup(driver.page_source, 'lxml'))
        # info = housing_info.to_dict()
        # info.update(new_info)
        if pbar:
            pbar.update()
        return pd.Series(new_info, name=housing_info.name)
    except TimeoutException:
        if pbar:
            pbar.update()
        return pd.Series(name=housing_info.name)


def click_next_page(driver):
    next_page_class_name = 'button--icon-right'
    WebDriverWait(driver, 2) \
        .until(EC.presence_of_element_located((By.CLASS_NAME,
                                               next_page_class_name)))
    next_page = driver.find_element_by_class_name(next_page_class_name)
    time.sleep(5)
    next_page.click()
    time.sleep(randint(1, 3))


def go_to_next_page(driver, page=None):
    url_pieces = driver.current_url.split('&')
    if page is None:
        idx = [idx for idx in range(len(url_pieces))
               if url_pieces[idx].startswith('page')]
        page = url_pieces[idx[0]] if idx else 1

    new_url = '&'.join([x for x in url_pieces if not x.startswith('page')]) \
        + f'&page={page + 1}'
    driver.get(new_url)
    time.sleep(randint(1, 3))


def save_df(df, file_name, selection_name=None):
    if selection_name:
        file_name = file_name.replace('{placeholder}', selection_name) \
            if '{placeholder}' in file_name else file_name
    df.to_csv(file_name)
    print(f'File {file_name} saved !')


def shut_driver(driver):
    driver.close()
