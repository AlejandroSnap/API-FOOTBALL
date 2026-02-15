from fastapi import APIRouter
from app.schemas.user_schema import UserCreateDTO
from app.services.user_service import create_user, get_all_users

router = APIRouter()

@router.post("/users")
def create(user: UserCreateDTO):
    user_id = create_user(user.dict())

    return {"id": user_id}

@router.get("/users")
def get_users():
    return get_all_users()