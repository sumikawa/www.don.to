#!/usr/bin/env python3

import glob, os, re, sys
from os.path import join, dirname
import mimetypes
import dropbox
import pprint
import hashlib
import yaml
from dotenv import load_dotenv

load_dotenv(verbose=True)
dotenv_path = join(dirname(__file__), '.env')
load_dotenv(dotenv_path)

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
  def get_yml(year):
    os.chdir(currentdir)
    path = "image/{year}.yml".format(year=year)
    if os.path.exists(path):
      with open(path, 'r') as f:
        yml[str(year)] = yaml.load(f, Loader=yaml.Loader) or {}
    else:
      yml[str(year)] = {}
    return(yml[str(year)])

  def save_yml():
    os.chdir(currentdir)
    for year, data in yml.items():
      path = "image/{year}.yml".format(year=year)
      with open(path, mode='w', encoding='utf-8') as f:
        yaml.safe_dump(data, f)
    os.chdir(rootdir + prefix)

  yml = {}

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

    yml.setdefault(year, get_yml(year))

    if not dirname in yml[year]:
      yml[year][dirname] = {}

    if not filename in yml[year][dirname].keys():
      print("generating url: {year}/{dirname}/{filename}".format(year=year, dirname=dirname, filename=filename), flush=True)
      url = sharing(file)
      url = url.replace('https://www.dropbox.com/', 'https://dl.dropboxusercontent.com/')
      yml[year][dirname][filename] = url
      count = count + 1

    if count == 30:
      print("writing yml", flush=True)
      save_yml()
      count = 0
      print("-> done", flush=True)

  print("writing final yml", flush=True)
  save_yml()
  print("-> done", flush=True)
