# This script will prompt you for an image file and attempt to extract the text from the image. 
# The script will print the text to the screen. 
# The script also saves the text to a file using the same filename as the image file with a .txt extension
# This was created to run on Windows but it should work on Linux and Mac as well but may require some small changes.
# Dependencies are:
# 1. Install Tesseract-OCR from https://github.com/UB-Mannheim/tesseract/wiki
# 2. Install pytesseract using pip install pytesseract

import sys
import pytesseract
from PIL import Image
import getpass

# Capture current usernam, this is used in Windows to make the path to the tesseract.exe support a variable user name
import getpass
USERNAME= getpass.getuser()

# Configure the path to an executable file with the directory name containing a parameterized username
# This is a workaround for the pytesseract.pytesseract.tesseract_cmd path issue
# https://stackoverflow.com/questions/50659482/runtimeerror-tesseract-is-not-installed-or-its-not-in-your-path
# https://stackoverflow.com/questions/50659482/runtimeerror-tesseract-is-not-installed-or-its-not-in-your-path/50659644
pytesseract.pytesseract.tesseract_cmd = r"C:\Users\%s\AppData\Local\Programs\Tesseract-OCR\tesseract.exe" % USERNAME

# Get the file name from the command line
fname = input('Enter file name: ')

# Open the image file
try:
    im = Image.open(fname)
except:
    print('File cannot be opened:', fname)
    sys.exit()

# Extract the text from the image
text = pytesseract.image_to_string(im)

# Output text to a file with the same name as the image file
with open(fname + '.txt', 'w') as f:
    f.write(text)

# Print the text to the screen
print(text)
print(f'The text output was saved to the file', fname + '.txt')
      

# Run the script from the command line
# python3 image2Text.py
