import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from .database import init_db
from .config import settings
from .routers import clothes, outfits, weather, events


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    os.makedirs(settings.images_dir, exist_ok=True)
    yield


app = FastAPI(
    title="Style Consultant AI",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve uploaded images as static files
app.mount("/images", StaticFiles(directory=settings.images_dir), name="images")

app.include_router(clothes.router)
app.include_router(outfits.router)
app.include_router(weather.router)
app.include_router(events.router)


@app.get("/health")
async def health():
    return {"status": "ok"}
