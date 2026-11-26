import asyncio
from app.config import get_settings
from app.services.gemini_service import GeminiService


async def main():
    service = GeminiService(get_settings())
    try:
        raw, model = await service._generate_with_fast_fallback({
            'contents': [{'role': 'user', 'parts': [{'text': 'Give one short hint for a linear equation.'}]}],
            'generationConfig': {'maxOutputTokens': 80},
        })
        print('UPSTREAM_OK', model, 'HAS_CANDIDATES', bool(raw.get('candidates')))
    except Exception as exc:
        print('UPSTREAM_EXCEPTION_TYPE', type(exc).__name__)
        print('UPSTREAM_ERROR_CODE', getattr(exc, 'code', 'unexpected'))
        print('CAUSE_TYPE', type(exc.__cause__).__name__ if exc.__cause__ else 'none')


asyncio.run(main())
