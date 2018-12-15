import requests
import json
import time
import re
import sys
from bson.json_util import loads 
import os.path

headers = { 'Accept': 'application/json' }
data = {'grant_type': 'client_credentials'}
token_appl = requests.post('http://172.18.0.15:5000/uaa/oauth/token', headers=headers, data=data, auth=('account-service', 'acc_serv'))
token = "Bearer"+str(token_appl)
headers=('Accept': 'application/json', 'Authorization': token  )

print('sending get request to http://172.18.0.15:8888/account-service/default')
response = requests.get('http://172.18.0.15:8888/account-service/default', headers=headers)
print('response: {0}'.format(response.content))
