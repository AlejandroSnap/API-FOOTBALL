from fastapi import APIRouter
from app.schemas.player_schema import *
from app.services.player_service import *

router = APIRouter()

@router.post("/players")
def create(player: Player):
    return create_player(player)

@router.patch("/players/{id}")
def patch(id: str, update: PlayerUpdate):
    return update_player(id, update)