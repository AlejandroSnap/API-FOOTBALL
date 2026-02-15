from fastapi import FastAPI
from pymongo import MongoClient
from app.routes.user_routes import router as user_router

app = FastAPI()

app.include_router(user_router)