text = "Café"
encoded_utf8 = text.encode('utf-8')  # UTF-8 encoding
encoded_ascii = text.encode('ascii', errors='ignore')  # ASCII encoding, ignoring non-ASCII characters

print(encoded_utf8)
print(encoded_ascii)
