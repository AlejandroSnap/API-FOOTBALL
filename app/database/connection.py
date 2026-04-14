import os
from pymongo import MongoClient
from dotenv import load_dotenv

# client = MongoClient("mongodb://user:admin@localhost:27017/?authSource=admin")

load_dotenv()

client = MongoClient(os.getenv("MONGO_URI"))

db = client["main"]