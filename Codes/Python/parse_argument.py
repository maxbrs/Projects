from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument('--acc',  '--accounts', nargs='+', default=[])
# list_accounts = list(map(int, parser.parse_args()._get_kwargs()[0][1]))
list_accounts = parser.parse_args()._get_kwargs()[0][1]

print(list_accounts)

# >>> python3 parse_argument.py --accounts 5 10 50
# [1] [5, 10, 50]

# 4301, 708369

