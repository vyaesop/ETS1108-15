ethiopian_dict = {
    "Food": "Injera",
    "Drink": "Ethiopian Coffee",
    "Landmark": "Lalibela",
    "Festival": "Meskel Festival"
}

# Get all key-value pairs as a view object
items_view = ethiopian_dict.items()

print("Items view:", items_view)

# Convert the items view to a list of tuples
items_list = list(items_view)

print("List of key-value pairs:", items_list)

# Iterate through the items
print("Iterating through items:")
for key, value in ethiopian_dict.items():
    print(f"{key}: {value}")