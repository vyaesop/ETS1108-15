user_input = "the quick brown fox jumps over the lazy dog"
keyword = "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG"

# Convert both strings to lowercase for case-insensitive comparison
if user_input.lower() == keyword.upper():
    print("The strings match!")
else:
    print("The strings are different.")
