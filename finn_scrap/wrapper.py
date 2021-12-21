#!/usr/bin/env python3
"""Finn scrap - wrapper

"""
from tqdm import tqdm
from finn_scrap.tools import load_parameters, init_driver, load_or_init_df, \
    search_nb_pages, wait_page_loading, scrap_search_page, go_to_next_page, \
    shut_driver, scrap_individual_page, save_df

CHUNK_SIZE = 100


if __name__ == '__main__':
    print('Initialize the search')
    parameters = load_parameters()
    for selection_name, selection_url in parameters['URLs'].items():
        print(f'Start the selection {selection_name}')
        driver = init_driver(selection_url)

        housing_df = load_or_init_df(parameters['file_name'], selection_name)

        if parameters['pages_to_scrap'] != 1:
            max_pages = search_nb_pages(driver.page_source)

            parameters['pages_to_scrap'] = max_pages if \
                parameters['pages_to_scrap'] == -1 else \
                max_pages if parameters['pages_to_scrap'] >= max_pages else \
                parameters['pages_to_scrap']

        print('Starting scrapping the pages')
        with tqdm(total=parameters['pages_to_scrap']) as pbar:
            for idx in range(parameters['pages_to_scrap']):
                wait_page_loading(driver)
                housing_df = scrap_search_page(driver.page_source, housing_df)
                go_to_next_page(driver, idx + 1)
                pbar.update()

        print('All pages loaded. Starting to scrap individual information')
        with tqdm(total=len(housing_df)) as pbar:
            for chunk_idx in range(0, len(housing_df), CHUNK_SIZE):
                chunk_housing_df = \
                    housing_df.iloc[chunk_idx:chunk_idx + CHUNK_SIZE]\
                    .apply(lambda info: scrap_individual_page(info,
                                                              driver,
                                                              pbar), axis=1)
                housing_df = housing_df\
                    .combine_first(chunk_housing_df)\
                    .reindex(housing_df.index)

                save_df(housing_df, parameters['file_name'], selection_name)

        save_df(housing_df, parameters['file_name'], selection_name)

        print('All info fully loaded')
        shut_driver(driver)
