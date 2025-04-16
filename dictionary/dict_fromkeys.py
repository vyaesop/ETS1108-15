ethiopian_keys = ["Food", "Drink", "Landmark", "Festival"]

# Create a dictionary with default value None
ethiopian_dict = dict.fromkeys(ethiopian_keys)

print("Dictionary with default values:", ethiopian_dict)

# Create a dictionary with a specific default value
ethiopian_dict_with_value = dict.fromkeys(ethiopian_keys, "Unknown")

print("Dictionary with custom default value:", ethiopian_dict_with_value)