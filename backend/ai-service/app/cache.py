import os
import redis
from redis.exceptions import RedisError

REDIS_URL = os.getenv(
	"REDIS_URL",
	f"redis://{os.getenv('REDIS_HOST', 'localhost')}:{os.getenv('REDIS_PORT', '6379')}",
).strip().strip('"').strip("'")


class BestEffortRedis:
	def __init__(self, url: str):
		self._client = redis.from_url(
			url,
			decode_responses=True,
			socket_connect_timeout=2,
			socket_timeout=2,
			retry_on_timeout=False,
		)

	def get(self, key: str):
		try:
			return self._client.get(key)
		except (OSError, RedisError):
			return None

	def setex(self, key: str, ttl: int, value: str):
		try:
			return self._client.setex(key, ttl, value)
		except (OSError, RedisError):
			return False


redis_client = BestEffortRedis(REDIS_URL)
