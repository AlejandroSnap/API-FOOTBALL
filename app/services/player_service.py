from fastapi import HTTPException

from app.database.connection import db
from app.schemas.player_schema import Player, PlayerUpdate

def create_player(player: Player):
    player_dict = player.model_dump()
    is_existing_player = db["players"].find_one({"id": player_dict["id"]})
    if is_existing_player:
        raise HTTPException(
            status_code=400,
            detail="The id is already taken."
        )

    response = db["players"].insert_one(player_dict)
    player_dict["_id"] = str(response.inserted_id)

    return player_dict

def update_player(id: str, update: PlayerUpdate):
    id = int(id)
    player = db["players"].find_one({"id": id})

    if not player:
        raise HTTPException(status_code=404, detail="Player doesnt found.")
    
    update_dict = update.model_dump(exclude_unset=True)
    if "career_goals" in update_dict and update_dict["career_goals"] < 0:
        raise HTTPException(
            status_code=400,
            detail="Goals cannot be negative."
        )


    db["players"].update_one(
        {"id": id},
        {"$set": update_dict}
    )

    updated_player = db["players"].find_one({"id": id})
    updated_player["_id"] = str(updated_player["_id"])

    return {"player": updated_player}