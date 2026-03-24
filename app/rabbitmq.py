import os
import json
import pika

QUEUE_NAME = os.getenv("RABBITMQ_QUEUE")

def get_connection_params():
    host = os.getenv("RABBITMQ_HOST")
    port = int(os.getenv("RABBITMQ_PORT"))
    user = os.getenv("RABBITMQ_USER")
    password = os.getenv("RABBITMQ_PASSWORD")

    credentials = pika.PlainCredentials(user, password)
    return pika.ConnectionParameters(
        host=host,
        port=port,
        credentials=credentials
    )

def publish_player_task(task_id: str, player_payload: dict):
    params = get_connection_params()
    connection = pika.BlockingConnection(params)
    channel = connection.channel()

    channel.queue_declare(queue=QUEUE_NAME, durable=True)

    body = json.dumps({
        "taskId": task_id,
        "payload": player_payload
    })

    channel.basic_publish(
        exchange="",
        routing_key=QUEUE_NAME,
        body=body
    )

    connection.close()