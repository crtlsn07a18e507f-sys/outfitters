import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from ..database import get_db
from ..models import CalendarEvent
from ..schemas import EventCreate, EventResponse

router = APIRouter(prefix="/events", tags=["events"])


@router.post("/", response_model=EventResponse)
async def create_event(data: EventCreate, db: AsyncSession = Depends(get_db)):
    event = CalendarEvent(id=str(uuid.uuid4()), **data.model_dump())
    db.add(event)
    await db.flush()
    await db.refresh(event)
    return event


@router.get("/user/{user_id}", response_model=list[EventResponse])
async def get_events(user_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(CalendarEvent)
        .where(CalendarEvent.user_id == user_id)
        .order_by(CalendarEvent.event_date)
    )
    return result.scalars().all()


@router.delete("/{event_id}")
async def delete_event(event_id: str, user_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(CalendarEvent).where(CalendarEvent.id == event_id, CalendarEvent.user_id == user_id)
    )
    event = result.scalar_one_or_none()
    if not event:
        raise HTTPException(404, "Event not found")
    await db.delete(event)
    return {"deleted": True}
