import os
from pymongo import MongoClient

# client = MongoClient("mongodb://user:admin@localhost:27017/?authSource=admin")
client = MongoClient(os.getenv("MONGO_URI"))

db = client["main"]