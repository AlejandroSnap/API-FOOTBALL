from pydantic import BaseModel

class UserCreateDTO(BaseModel):
    name: str
    age: int

class UserResponseDTO(BaseModel):
    id: str
    name: str
    age: int