import json

path = '/home/kirancybergrid/Documents/vautiz password mamnager/assets/database/popular_services.json'

with open(path, 'r') as f:
    data = json.load(f)

new_entries = [
    {"name": "Kerala Vision", "domain": "keralavisionisp.com"},
    {"name": "HDFC Bank", "domain": "hdfcbank.com"},
    {"name": "SBI Bank", "domain": "onlinesbi.sbi"},
    {"name": "ICICI Bank", "domain": "icicibank.com"},
    {"name": "Axis Bank", "domain": "axisbank.com"},
    {"name": "Federal Bank", "domain": "federalbank.co.in"},
    {"name": "Kotak Mahindra", "domain": "kotak.com"},
    {"name": "Visa", "domain": "visa.com"},
    {"name": "Mastercard", "domain": "mastercard.com"},
    {"name": "American Express", "domain": "americanexpress.com"},
    {"name": "RuPay", "domain": "rupay.co.in"},
    {"name": "Jio", "domain": "jio.com"},
    {"name": "Airtel", "domain": "airtel.in"},
    {"name": "BSNL", "domain": "bsnl.co.in"},
    {"name": "Vi (Vodafone Idea)", "domain": "myvi.in"}
]

# prepend new entries
data = new_entries + data

with open(path, 'w') as f:
    json.dump(data, f, separators=(',', ':'))

print("Updated popular_services.json")
