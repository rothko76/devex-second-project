from flask import Flask, jsonify, request
import boto3
import json
import os

# Flask app initialization
app = Flask(__name__)

# Initialize the Kinesis client
kinesis_client = boto3.client('kinesis', region_name='us-east-1')

# Kinesis stream name (you need to replace with your stream name)
KINESIS_STREAM_NAME = 'product'


@app.route('/')
def index():
   # send_data()
    return "Welcome to the Data Streaming Demo!"


# Producer: Send data to the Kinesis stream
@app.route('/send', methods=['POST'])
def send_data():
    data = request.json
    partition_key = data.get("partition_key", "default_key")

    # Send data to Kinesis
    response = kinesis_client.put_record(
        StreamName=KINESIS_STREAM_NAME,
        Data=json.dumps(data),
        PartitionKey=partition_key
    )

    return jsonify({"status": "Data sent to Kinesis", "response": response})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
