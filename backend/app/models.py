import uuid
from datetime import datetime
from sqlalchemy import String, Float, Integer, Boolean, DateTime, JSON, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from .database import Base


def gen_uuid() -> str:
    return str(uuid.uuid4())


class ClothingItem(Base):
    __tablename__ = "clothing_items"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=gen_uuid)
    user_id: Mapped[str] = mapped_column(String, index=True, nullable=False)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    category: Mapped[str] = mapped_column(String(50), nullable=False)       # top/bottom/shoes/jacket/accessory
    color: Mapped[str] = mapped_column(String(100), nullable=False)
    material: Mapped[str] = mapped_column(String(200), nullable=False)
    temp_min: Mapped[float] = mapped_column(Float, nullable=False)           # °C
    temp_max: Mapped[float] = mapped_column(Float, nullable=False)           # °C
    suitable_occasions: Mapped[list] = mapped_column(JSON, default=list)     # ["casual","formal","sport"]
    image_filename: Mapped[str] = mapped_column(String(300), nullable=False)
    ai_description: Mapped[str] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    outfit_items: Mapped[list["OutfitItem"]] = relationship(
        back_populates="clothing", cascade="all, delete-orphan"
    )


class Outfit(Base):
    __tablename__ = "outfits"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=gen_uuid)
    user_id: Mapped[str] = mapped_column(String, index=True, nullable=False)
    liked: Mapped[bool] = mapped_column(Boolean, nullable=True, default=None)  # None=neutral, True=like, False=dislike
    occasion: Mapped[str] = mapped_column(String(100), nullable=True)
    weather_condition: Mapped[str] = mapped_column(String(100), nullable=True)
    temperature: Mapped[float] = mapped_column(Float, nullable=True)
    ai_explanation: Mapped[str] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    items: Mapped[list["OutfitItem"]] = relationship(
        back_populates="outfit", cascade="all, delete-orphan", lazy="selectin"
    )


class OutfitItem(Base):
    __tablename__ = "outfit_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    outfit_id: Mapped[str] = mapped_column(String, ForeignKey("outfits.id", ondelete="CASCADE"))
    clothing_id: Mapped[str] = mapped_column(String, ForeignKey("clothing_items.id", ondelete="CASCADE"))
    layer_order: Mapped[int] = mapped_column(Integer, default=0)  # display order (0=bottom)

    outfit: Mapped["Outfit"] = relationship(back_populates="items")
    clothing: Mapped["ClothingItem"] = relationship(back_populates="outfit_items")


class CalendarEvent(Base):
    __tablename__ = "calendar_events"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=gen_uuid)
    user_id: Mapped[str] = mapped_column(String, index=True, nullable=False)
    title: Mapped[str] = mapped_column(String(300), nullable=False)
    occasion_type: Mapped[str] = mapped_column(String(50), nullable=False)  # casual/formal/sport/business/party
    event_date: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    notes: Mapped[str] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
