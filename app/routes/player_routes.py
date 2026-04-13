from fastapi import APIRouter
from app.schemas.player_schema import *
from app.services.player_service import *

router = APIRouter()

@router.get("/players")
def get_players():
    return get_all_players()

@router.get("/players/{id}")
def get_player(id: str):
    return get_player_by_id(id)

@router.post("/players")
def create(player: Player):
    return create_player(player)

@router.patch("/players/{id}")
def patch(id: str, update: PlayerUpdate):
    return update_player(id, update)

@router.delete("/players/{id}")
def remove_user(id: str):
    return delete_player(id)