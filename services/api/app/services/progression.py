"""Read-only projections from authoritative reward events (progress-v1)."""
from datetime import datetime, timedelta, timezone
from math import isqrt
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


def progress_level(xp: int) -> dict:
    xp = max(0, xp)
    level = 1 + isqrt(xp // 100)
    floor = 100 * (level - 1) ** 2
    ceiling = 100 * level ** 2
    return {
        'level': level,
        'levelStartXp': floor,
        'nextLevelXp': ceiling,
        'xpIntoLevel': xp - floor,
        'xpToNextLevel': ceiling - xp,
        'progressVersion': 'progress-v1',
    }


def review_streak(events: list[datetime], time_zone: str, now: datetime) -> int:
    try:
        zone = ZoneInfo(time_zone)
    except ZoneInfoNotFoundError:
        zone = ZoneInfo('Asia/Ho_Chi_Minh')
    def aware(value: datetime) -> datetime:
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    today = aware(now).astimezone(zone).date()
    days = {
        aware(event).astimezone(zone).date()
        for event in events if aware(event) <= aware(now)
    }
    cursor = today if today in days else today - timedelta(days=1)
    count = 0
    while cursor in days:
        count += 1
        cursor -= timedelta(days=1)
    return count
