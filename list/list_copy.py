ethiopian_stuff = ["Injera", "Doro Wat", "Lalibela", "Ethiopian Coffee", "Meskel Festival"]

# Create a copy of the list
ethiopian_stuff_copy = ethiopian_stuff.copy()

print("Original list:", ethiopian_stuff)
print("Copied list:", ethiopian_stuff_copy)

# Modify the original list to show the copied list is unaffected
ethiopian_stuff.append("Teff")

print("Modified original list:", ethiopian_stuff)
print("Copied list remains unchanged:", ethiopian_stuff_copy)