import redis
import os

try:
    redis_host = os.getenv("REDIS_HOST", "localhost")
    redis_client = redis.Redis(host=redis_host, port=6379, db=0, socket_connect_timeout=1, decode_responses=True)
    redis_client.ping()
except redis.ConnectionError:
    # Fallback to a mock-like behavior if Redis is down
    print("WARNING: Redis is not available. Using in-memory fallback (mock).")
    class MockRedis:
        def __init__(self): self.data = {}
        def get(self, key): return self.data.get(key)
        def set(self, key, value): self.data[key] = value
        def setex(self, name, time, value): self.data[name] = value
    redis_client = MockRedis()
