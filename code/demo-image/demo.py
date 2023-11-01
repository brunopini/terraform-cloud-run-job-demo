import requests

import base64
import json
import os

print('Hello, World!', '\n')

url = 'https://httpbin.org/get'
response = requests.get(url)

print(f'Status Code: {response.status_code}', '\n')
print(f'Response Content: {response.json()}', '\n')

service_account_info = json.loads(
    base64.b64decode(
        os.environ['GOOGLE_APPLICATION_CREDENTIALS_JSON']
    ).decode('UTF-8')
)

print(f'GOOGLE_APPLICATION_CREDENTIALS_JSON: {service_account_info}', '\n')

print('Goodbye, World... :(')
