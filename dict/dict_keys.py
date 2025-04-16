ethiopian_dict = {
    "Food": "Injera",
    "Drink": "Ethiopian Coffee",
    "Landmark": "Lalibela",
    "Festival": "Meskel Festival"
}

# Get all keys as a view object
keys_view = ethiopian_dict.keys()

print("Keys view:", keys_view)

# Convert the keys view to a list
keys_list = list(keys_view)

print("List of keys:", keys_list)

# Iterate through the keys
print("Iterating through keys:")
for key in ethiopian_dict.keys():
    print(key)