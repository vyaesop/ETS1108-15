ethiopian_dict = {
    "Food": "Injera",
    "Drink": "Ethiopian Coffee",
    "Landmark": "Lalibela",
    "Festival": "Meskel Festival"
}

# Remove and return the value for the key "Drink"
removed_value = ethiopian_dict.pop("Drink")
print("Removed value:", removed_value)
print("Updated dictionary:", ethiopian_dict)

# Try to remove a key that doesn't exist, with a default message
non_existent_value = ethiopian_dict.pop("Music", "Key not found")
print("Value for non-existent key:", non_existent_value)
