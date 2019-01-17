import requests
import json
import time
import re
import sys
from bson.json_util import loads
import os.path


headers = { 'Accept': 'application/json', 'Content-Type': 'application/json' }
print('sending post request to http://localhost:6000/accounts/')
json_content = {"username":"TestDue","password":"password"}
response = requests.post('http://localhost:6000/accounts/', data=json.dumps(json_content), headers=headers)
print('response: {0}'.format(response.content))
if response.status_code == 201:
	print('created')

headers = { 'Accept': 'application/json', 'Content-Type': 'application/json' }
headers = {'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer b52d8972-f588-4a98-86e0-65272cda65af'}

data = {}
data = json.loads('{"name":"LucaTestDue","lastSeen":"2018-12-14T08:51:43.294+0000","incomes":[{"title":"Salary","amount":20000.0,"currency":"USD","period":"YEAR","icon":"wallet"},{"title":"Scholarship","amount":500.0,"currency":"USD","period":"MONTH","icon":"edu"}],"expenses":[{"title":"Rent","amount":500.0,"currency":"USD","period":"MONTH","icon":"home"},{"title":"Utilities","amount":200.0,"currency":"USD","period":"MONTH","icon":"utilities"},{"title":"Meal","amount":100.0,"currency":"USD","period":"DAY","icon":"meal"},{"title":"Gas","amount":60.0,"currency":"USD","period":"MONTH","icon":"gas"},{"title":"Vacation","amount":1000.0,"currency":"EUR","period":"YEAR","icon":"island"},{"title":"Phone","amount":10.0,"currency":"EUR","period":"MONTH","icon":"phone"}],"saving":{"amount":2000.0,"currency":"USD","interest":3.32,"deposit":true,"capitalization":false},"note":"Prova di test 1.0"}')
print('sending put request to http://localhost:6000/accounts/current')
response = requests.put('http://localhost:6000/accounts/current', data = json.dumps(data), headers=headers)
print('response: {0}'.format(response.content))

headers = { 'Accept': 'application/json', 'Content-Type': 'application/json' }
print('sending post request to http://localhost:6000/accounts/')
json_content = {"username":"TestDue","password":"password"}
response = requests.post('http://localhost:6000/accounts/', data=json.dumps(json_content), headers=headers)
print('response: {0}'.format(response.content))
if response.status_code == 201:
	print('created')

