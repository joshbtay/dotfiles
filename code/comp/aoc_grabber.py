#!/bin/python
import requests
from sys import argv
URL = "https://adventofcode.com/2022/day/" + argv[1]
from bs4 import BeautifulSoup as bs
page = requests.get(URL)
soup = bs(page.content, "html.parser")
codes = soup.find_all("code")
content = codes[0].text
if len(codes) != 1:
    for c in codes:
        print("Is this the input?")
        print(c.text)
        r = input()
        if r in 'yuiophjkl;bnm,.':
            content = c.text
            break

print(soup)