ethiopian_dict = {
    "Food": "Injera",
    "Drink": "Ethiopian Coffee",
    "Landmark": "Lalibela",
    "Festival": "Meskel Festival"
}

# Get the value for the key "Food"
food = ethiopian_dict.get("Food")
print("Value for 'Food':", food)

# Try to get the value for a key that doesn't exist, with a default message
non_existent = ethiopian_dict.get("Music", "Key not found")
print("Value for 'Music':", non_existent)

# Try to get the value for a key that doesn't exist, without a default message
non_existent_no_default = ethiopian_dict.get("Music")
print("Value for 'Music' (no default):", non_existent_no_default)