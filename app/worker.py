import json
import os
import pika
from pymongo import MongoClient
from database.connection import db
from bson import ObjectId

players_collection = db["players"]

QUEUE_NAME = os.getenv("RABBITMQ_QUEUE", "player_tasks")
print(os.getenv("RABBITMQ_QUEUE"))


def process_message(ch, method, properties, body):
    try:
        message = json.loads(body)
        payload = message["payload"]
        action = payload.get("action", "create")

        print(f"[Worker] Acción: {action}")

        if action == "delete":
            player_id = payload["player_id"]
            result = players_collection.delete_one(
                {"_id": ObjectId(player_id)}
            )

            if result.deleted_count == 0:
                print(f"[Worker] Jugador no encontrado: {player_id}")
            else:
                print(f"[Worker] Jugador eliminado: {player_id}")

        else:
            payload.pop("action", None)
            players_collection.insert_one(payload)
            print("[Worker] Jugador creado")

        ch.basic_ack(delivery_tag=method.delivery_tag)

    except Exception as e:
        print(f"[Worker] Error: {e}")
        ch.basic_ack(delivery_tag=method.delivery_tag)


def main():
    host = os.getenv("RABBITMQ_HOST")
    port = int(os.getenv("RABBITMQ_PORT"))
    user = os.getenv("RABBITMQ_USER")
    password = os.getenv("RABBITMQ_PASSWORD")

    credentials = pika.PlainCredentials(user, password)
    params = pika.ConnectionParameters(
        host=host,
        port=port,
        credentials=credentials
    )

    connection = pika.BlockingConnection(params)
    channel = connection.channel()

    channel.queue_declare(queue=QUEUE_NAME, durable=True)
    channel.basic_qos(prefetch_count=1)

    channel.basic_consume(
        queue=QUEUE_NAME,
        on_message_callback=process_message
    )

    print(f"[Worker] Esperando mensajes en '{QUEUE_NAME}'...")
    channel.start_consuming()


if __name__ == "__main__":
    main()