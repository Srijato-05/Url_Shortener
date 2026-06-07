import string
import random
import re
import os
import socket
from fastapi import Request # type: ignore
from typing import Optional

def generate_short_code(length=6):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

RESERVED_WORDS = {'localhost', 'stats', 'qr', 'docs', 'redoc', 'health', 'api', 'admin'}

def get_primary_ip() -> str:
    """
    Attempts to discover the primary local IP address of the host.
    """
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Connect to a target that doesn't need to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

def get_base_url(request) -> str:
    # 1. Environment Override (Highest Priority)
    env_base_url = os.getenv("API_BASE_URL", "").rstrip("/")
    if env_base_url:
        return env_base_url

    # 2. Extract Client-Provided Host Metadata
    # Trust X-Forwarded headers (proxies/tunnels) or standard Host header
    host = request.headers.get("X-Forwarded-Host", request.headers.get("host", "localhost:8000"))
    scheme = request.headers.get("X-Forwarded-Proto", request.url.scheme)

    # 3. Dynamic Loopback Sanitization using host's mDNS hostname
    if any(lb in host.lower() for lb in ["localhost", "127.0.0.1", "[::1]", "0.0.0.0"]):
        host_hostname = os.getenv("HOST_HOSTNAME")
        if host_hostname and host_hostname.lower() != "localhost":
            if ":" in host:
                port = host.split(":")[1]
                host = f"{host_hostname}.local:{port}"
            else:
                host = f"{host_hostname}.local"

    return f"{scheme}://{host}"

def scrape_metadata(url: str):
    import requests # type: ignore
    from bs4 import BeautifulSoup # type: ignore
    from urllib.parse import urljoin, urlparse

    try:
        response = requests.get(url, timeout=5, headers={"User-Agent": "Mozilla/5.0"})
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')

        # 1. Title Discovery
        title = soup.find('meta', property='og:title')
        title = title['content'] if title else (soup.title.string if soup.title else None)
        if title:
            title = title.strip()

        # 2. Description Discovery
        description = soup.find('meta', property='og:description')
        if not description:
            description = soup.find('meta', attrs={'name': 'description'})
        description = description['content'] if description else None
        if description:
            description = description.strip()

        # 3. Favicon Discovery
        favicon = soup.find('link', rel=re.compile(r'icon', re.I))
        favicon_url = favicon['href'] if favicon else '/favicon.ico'
        # Convert relative to absolute
        favicon_url = urljoin(url, favicon_url)

        return {
            "title": title[:255] if title else None,
            "description": description[:500] if description else None,
            "favicon_url": favicon_url
        }
    except Exception as e:
        print(f"Metadata scraping failed for {url}: {e}")
        return {"title": None, "description": None, "favicon_url": None}

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
