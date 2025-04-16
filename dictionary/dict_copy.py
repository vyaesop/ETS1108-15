ethiopian_dict = {
    "Food": "Injera",
    "Drink": "Ethiopian Coffee",
    "Landmark": "Lalibela",
    "Festival": "Meskel Festival"
}

# Create a copy of the dictionary
ethiopian_dict_copy = ethiopian_dict.copy()

print("Original dictionary:", ethiopian_dict)
print("Copied dictionary:", ethiopian_dict_copy)

# Modify the original dictionary to show the copied dictionary is unaffected
ethiopian_dict["Food"] = "Doro Wat"

print("Modified original dictionary:", ethiopian_dict)
print("Copied dictionary remains unchanged:", ethiopian_dict_copy)