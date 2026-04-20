"""AI service — OpenAI transcription."""
import logging
from fastapi import HTTPException, UploadFile

logger = logging.getLogger(__name__)


class AIService:
    def __init__(self, api_key: str) -> None:
        if not api_key or api_key == "your_openai_api_key_here":
            raise HTTPException(status_code=503, detail="OpenAI API key not configured")
        from openai import AsyncOpenAI
        self._client = AsyncOpenAI(api_key=api_key)

    async def transcribe(self, file: UploadFile) -> str:
        """Send audio file to OpenAI gpt-4o-transcribe and return transcript text."""
        try:
            contents = await file.read()
            # OpenAI SDK expects a file-like tuple: (filename, bytes, content_type)
            response = await self._client.audio.transcriptions.create(
                model="gpt-4o-transcribe",
                file=(file.filename or "audio.webm", contents, file.content_type or "audio/webm"),
                response_format="text",
            )
            return response if isinstance(response, str) else response.text
        except HTTPException:
            raise
        except Exception as exc:
            logger.error("Transcription failed: %s", exc)
            raise HTTPException(status_code=500, detail=f"Transcription failed: {str(exc)}") from exc


def get_ai_service() -> AIService:
    from app.config import settings
    return AIService(api_key=settings.openai_api_key)
