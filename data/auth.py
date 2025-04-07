#!/usr/bin/env python3

import os
from dropbox import DropboxOAuth2FlowNoRedirect

APP_KEY = os.environ["DROPBOX_APP_KEY"]
APP_SECRET = os.environ["DROPBOX_APP_SECRET"]

auth_flow = DropboxOAuth2FlowNoRedirect(
                        APP_KEY,
                        consumer_secret=APP_SECRET,
                        use_pkce=False,
                        token_access_type='offline'
)

authorize_url = auth_flow.start()
print("1. Go to: " + authorize_url)
print("2. Click \"Allow\" (you might have to log in first).")
print("3. Copy the authorization code.")
auth_code = input("Enter the authorization code here: ").strip()

oauth_result = auth_flow.finish(auth_code)
print(oauth_result.refresh_token)
