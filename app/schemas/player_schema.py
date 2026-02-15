from pydantic import BaseModel
from typing import Optional
from enum import Enum

class Position(str, Enum):
    GK = "GK"
    DEF = "DEF"
    MID = "MID"
    FWD = "FWD"

class Player(BaseModel):
    id: int
    name: str
    team_id: int
    career_goals: int
    jersey_number: int
    position: Position

class PlayerUpdate(BaseModel):
    name: Optional[str] = None
    team_id: Optional[int] = None
    career_goals: Optional[int] = None
    jersey_number: Optional[int] = None
    position: Optional[Position] = None