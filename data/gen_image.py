#!/usr/bin/env python3

import glob, os, re, sys
import mimetypes
import dropbox
import pprint
import hashlib
import yaml

APP_KEY = os.environ["DROPBOX_APP_KEY"]
APP_SECRET = os.environ["DROPBOX_APP_SECRET"]
REFRESH_TOKEN = os.environ["DROPBOX_REFRESH_TOKEN"]

dbx = dropbox.Dropbox(oauth2_refresh_token=REFRESH_TOKEN, app_key=APP_KEY, app_secret=APP_SECRET)

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

  count = 0

  if len(sys.argv) == 2:
    list = glob.glob('*/{year}/**/*.*'.format(year=sys.argv[1]), recursive=True)
  else:
    list = glob.glob('**/*.*', recursive=True)

  s_list = sorted(list, reverse=True)
  for item in s_list:
    file = "{prefix}/{item}".format(prefix=prefix, item=item)
    layers = file.replace(prefix, '').split('/')
    year = str(layers[2])
    dirname = layers[3]
    filename = layers[4]

    if not year in yml:
      yml[year] = {}

    if not dirname in yml[year]:
      yml[year][dirname] = {}

    if not filename in yml[year][dirname].keys():
      print("generating url: {year}/{dirname}/{filename}".format(year=year, dirname=dirname, filename=filename), flush=True)
      url = sharing(file)
      url = url.replace('https://www.dropbox.com/', 'https://dl.dropboxusercontent.com/')
      yml[year][dirname][filename] = url
      count = count + 1
    # else:
    #   print("  skip url: {year}/{dirname}/{filename}".format(year=year, dirname=dirname, filename=filename))

    if count == 30:
      print("writing yml", flush=True)
      os.chdir(currentdir)
      with open('image.yml', mode='w', encoding='utf-8') as new_file:
        yaml.safe_dump(yml, new_file)
      os.chdir(rootdir + prefix)
      count = 0
      print("-> done", flush=True)

  os.chdir(currentdir)
  with open('image.yml', mode='w', encoding='utf-8') as new_file:
    yaml.safe_dump(yml, new_file)
  os.chdir(rootdir + prefix)
