#!/usr/bin/env python3

import glob, os, re
import mimetypes
import dropbox
import pprint
import hashlib
import yaml

app_key = 'm9hx41db0u6ix1b'
app_secret = 'pfdy698oyxat0xa'
access_token = 'sl.u.AFeDYhQyyn2XgUXs2mnAl8a2PCX1LUb0ESPbZYI-Y1skbA0I5xWwe7Cw8FBRMimi6cdxLHA5w5PakhdZBQTO_RH1xu-zytpQ5whbTOsjYGfTUEZf_X0yX7bDIx1phLFTA1aCnS9zfZDVaYSZJhxIuhvleY6d0xWUz1x3CuBtfa1TgystqbaGBR0rQYHKfsMakgF_zgXQAeliFRSnsKgQ9JCH0HN8k5AQlyvQ-jSLM7XEN4O6EWTSNmNYQyS39iMSG36NsX3jUK_6n55aLq4qmHZ8rBZYPsgyqyFgDEd8udw6dXQkcL5jUQ7uLbOguBkXD7jTZRw5nK__OD-bSU4SF772PFdTkaXk4uhHIohJfg8uaS4f_6R5baqmHf_1FT5-BvfeIycUJfGhfQK4EXZyt0ACHCX-N4W1aV57qMMTbnPrdREH-eJhRLu8L-kNP1kVlJnRLT5ehqxzCaj328SRuqCiU46D6xo-klAfyXYLV7NBG0hBktzSCahC_Unchu0gNOkfDmm8h4AXK9mpDBnZTDm1wRLb_zFIZOGvk77a9tSHCRQ0zmaGM4jcI54LDRQmu1yVFtKLRnpblwjJKlARXHcs-j29ZM1Fi6R1jKWL9r2fx64HTyaZ8PkH0bJqeTuyLa0EFWDHAYTanIuUqdxGnsH6K5ovwvk7CGgNjpy3kYGpUsEwCyofjdekRRbv0FKmTuTsm22IicIfgzP-YRcN5sCaniGGM6CbWodZpqjqQkk1G_xznSBlhY1tA2gDQ0oQ3yMSYQHLCIJGpbnvIU_EsAb_v-O2PKGJTDKQ6xbJNIDA67fFl15ZEXKTeKWxk6Nu0A7ozT6d-YrMNOA98NZxLiJICxpe99knnzu8ta5FIbCdlmhI5QJq8IScTduxp4fGhG9R3yHYlcfOCKksZgVsU4wcRU0nU8NovZ3vheAce_g2SdrOb9QftX_O7ov45ayUPhv_5ftBCVM6-D3bu9oRwgDd29RP7v3tOYpqXMAA5_yoXBlTb5p-NVNoXtxlK20UzTw8Jr1SZibss9f2ayXZUFm3S1sFNDpcrrG104qeG5qb38XpsQXfr-rkuqiN9m28oQ1TdmPmAyQdhAVrvjQAE6i2lRu6QpZjzOPgNrW-_w7LVBTr0XcCGpsQJYwIp0n55x-BvqBhiSPZX4OUjbUIhPWvmQUuIaEIxyGymmWBeEkSvCW_5FSmRpSa855iHT5nzKymMUnz0HqppUMJ4tJmnhRmHfo00dDmU-CClYMpCu_PebynYZ36TzUMZZF82Kr00TI7KakGW1Lew218f0c6T4Iw1yam-tcHiCQ7PGzm_V25vvUMDwZwjUK8RcrLeAjRwmo'

dbx = dropbox.Dropbox(access_token)

def sharing(path):
  try:
    setting = dropbox.sharing.SharedLinkSettings(requested_visibility=dropbox.sharing.RequestedVisibility.public)
    link = dbx.sharing_create_shared_link_with_settings(path=path, settings=setting)
  except:
    pass

  links = dbx.sharing_list_shared_links(path=path, direct_only=True).links
  # print(links)
  return(links[0].url)

if __name__ == "__main__":
  with open('image.yml') as original_file:
    yml = yaml.load(original_file, Loader=yaml.Loader)

  rootdir = "/Users/sumikawa/Dropbox"
  prefix = "/.cache"
  currentdir = os.getcwd()
  os.chdir(rootdir + prefix)

  list = glob.glob('*/2024/**/*.*', recursive=True)
  for item in list:
    file = "{prefix}/{item}".format(prefix=prefix, item=item)
    layers = file.replace(prefix, '').split('/')
    year = str(layers[2])
    dirname = layers[3]
    filename = layers[4]

    if not year in yml:
      yml[year] = {}

    if not dirname in yml[year]:
      yml[year][dirname] = {}

    if not filename in yml[year][dirname]:
      print("generating url: {year}/{dirname}/{filename}".format(year=year, dirname=dirname, filename=filename))
      url = sharing(file)
      url = url.replace('https://www.dropbox.com/', 'https://dl.dropboxusercontent.com/').replace('&dl=0', '&dl=1')
      yml[year][dirname][filename] = url
    # else:
      # print("skip url: {year}/{dirname}/{filename}".format(year=year, dirname=dirname, filename=filename))

  os.chdir(currentdir)
  with open('image_new.yml', mode='w', encoding='utf-8') as new_file:
    yaml.safe_dump(yml, new_file)
