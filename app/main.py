"""Small Claude + EC2 practice service."""

import os
from typing import Any

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="Claude EC2 Lab", version="0.1.0")


class AskRequest(BaseModel):
    prompt: str = Field(min_length=1, max_length=4000)


@app.get("/")
def root() -> dict[str, str]:
    return {"service": "claude-ec2-lab", "docs": "/docs", "health": "/health"}


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/config")
def config() -> dict[str, Any]:
    """Expose safe runtime information, never secrets."""
    return {
        "environment": os.getenv("APP_ENV", "local"),
        "model": os.getenv("CLAUDE_MODEL", "claude-sonnet-4-6"),
        "api_key_configured": bool(os.getenv("ANTHROPIC_API_KEY")),
    }


@app.post("/ask")
def ask(request: AskRequest) -> dict[str, str]:
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        raise HTTPException(
            status_code=503,
            detail="ANTHROPIC_API_KEY is not configured; /health still works.",
        )

    # Import only when needed so health endpoints remain dependency-light.
    from anthropic import Anthropic

    client = Anthropic(api_key=api_key)
    response = client.messages.create(
        model=os.getenv("CLAUDE_MODEL", "claude-sonnet-4-6"),
        max_tokens=512,
        messages=[{"role": "user", "content": request.prompt}],
    )
    text = "".join(block.text for block in response.content if block.type == "text")
    return {"model": response.model, "answer": text}
