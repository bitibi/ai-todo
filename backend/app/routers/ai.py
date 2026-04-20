"""AI endpoints."""
from fastapi import APIRouter, Depends, UploadFile, File
from app.middleware.auth import get_current_user
from app.services.ai_service import AIService, get_ai_service

router = APIRouter(prefix="/ai", tags=["AI"])


@router.post("/transcribe")
async def transcribe_audio(
    audio: UploadFile = File(..., description="Audio file to transcribe (webm, mp4, wav, etc.)"),
    _user: dict = Depends(get_current_user),
    ai_service: AIService = Depends(get_ai_service),
) -> dict:
    """
    Transcribe audio using OpenAI gpt-4o-transcribe.
    Returns: {"text": "transcribed text here"}
    """
    text = await ai_service.transcribe(audio)
    return {"text": text}
