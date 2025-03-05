from dropbox import DropboxOAuth2FlowNoRedirect

app_key = 'xxx'
app_secret = 'xxx'

auth_flow = DropboxOAuth2FlowNoRedirect(
                        app_key,
                        consumer_secret=app_secret,
                        use_pkce=False,
                        token_access_type='offline'
)

# auth_flow = DropboxOAuth2FlowNoRedirect(APP_KEY, APP_SECRET)

authorize_url = auth_flow.start()
print("1. Go to: " + authorize_url)
print("2. Click \"Allow\" (you might have to log in first).")
print("3. Copy the authorization code.")
auth_code = input("Enter the authorization code here: ").strip()

oauth_result = auth_flow.finish(auth_code)
print(oauth_result.refresh_token)
