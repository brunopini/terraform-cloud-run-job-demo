import requests

print('Hello, World!', '\n')

url = 'https://httpbin.org/get'
response = requests.get(url)

print(f'Status Code: {response.status_code}', '\n')
print(f'Response Content: {response.json()}')
