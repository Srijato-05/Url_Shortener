import os
import redis # type: ignore

# Connect directly to the real Redis service
redis_url = os.getenv("REDIS_URL", "redis://redis:6379/0")
redis_client = redis.Redis.from_url(
    redis_url,
    decode_responses=True,
    socket_connect_timeout=2
)
