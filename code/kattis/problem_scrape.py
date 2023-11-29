from bs4 import BeautifulSoup
import os

with open("/home/taylor/Downloads/kattis.html") as fp:
    soup = BeautifulSoup(fp, "html.parser")
l = soup.find_all("tr")
s = set()
for line in l:
    for a in line.find_all("a"):
        ref = a['href'].split('/')
        if len(ref) >4:
            s.add(ref[4])
print(len(s))
#for line in s:
    #print(line)
    #os.system('python add_problem -c go6h2h -p '+ line)
    #input()

