from app.database.connection import db
from app.schemas.user_schema import UserCreateDTO

def create_user(dto: UserCreateDTO):
    response = db.users.insert_one(dto)
    return str(response.inserted_id)

def get_all_users():
    users = []
    for user in db.users.find():
        user["_id"] = str(user["_id"])
        users.append(user)
    return users