#!/usr/bin/env python3
import deepl
import sys
import argparse
from pathlib import Path
home = Path.home()
try:
    with open(home / ".deepl_auth_key", 'r') as file:
        deepl_auth_key = file.read().rstrip()
    #rstrip ensures it doesn't get confused by a newline character
except OSError:
    print ('You need a DeepL API auth key to use this script.')
    print ('Please store your key as a text file in your home directory and name it .deepl_auth_key')
    '''
    /home/USERNAME/.deepl_auth_key in Linux
    /Users/USERNAME/.deepl_auth_key in macOS
    C:/Users/USERNAME/.deepl_auth_key in Windows
    /data/data/com.termux/files/home/.deepl_auth_key in Android (using Termux)
    any other UNIX-based system -- whatever $HOME/.deepl_auth_key expands to
    '''
    sys.exit(1)
parser = argparse.ArgumentParser()
parser.add_argument("file", help="text file to translate")
args = parser.parse_args()
text_file = (args.file)
with open(text_file, 'r') as file:
    contents = file.read()
#make sure the authkey is passed as a string and not an object
auth_key = str(deepl_auth_key)
translator = deepl.Translator(auth_key)
result = translator.translate_text(contents, target_lang="ES")
print(result.text)
deepl_client = deepl.DeepLClient(auth_key)
usage = deepl_client.get_usage()
if usage.any_limit_reached:
    print('Translation limit reached.')
if usage.character.valid:
    print('\033[34;1m', end='')
    print(f"Character usage: {usage.character.count} of {usage.character.limit}")
    print('\x1b[0m', end='')
