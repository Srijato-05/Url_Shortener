import string
import random
import re
from typing import Optional

def generate_short_code(length=6):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

RESERVED_WORDS = {'localhost', 'stats', 'qr', 'docs', 'redoc', 'health', 'api', 'admin'}

def is_valid_alias(alias: str) -> bool:
    """
    Validates that the custom alias follows professional URL standards:
    - Alphanumeric, underscores, or hyphens only.
    - Length between 3 and 32 characters.
    - Cannot be a reserved system word.
    """
    if not 3 <= len(alias) <= 32:
        return False
    
    if alias.lower() in RESERVED_WORDS:
        return False
        
    return bool(re.match(r"^[a-zA-Z0-9_-]+$", alias))
