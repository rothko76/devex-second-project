import json
import os
import json
import psycopg2
from psycopg2.extras import RealDictCursor


def lambda_handler(event, context):


    # Read the message from the stream
    if 'Records' in event:
        for record in event['Records']:
            # Assuming the stream is an SQS event
            if 'body' in record:
                message = record['body']
                print(f"Message from stream: {message}")
            else:
                print("No 'body' found in record")
    else:
        print("No 'Records' found in event")


    db_host = os.environ['DB_HOST']
    db_port = 5432 #os.environ['DB_PORT']
    db_name = os.environ['DB_NAME']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    print("Environment Variables:")
    print(f"DB_USER: {db_user}")
    print(f"DB_PASSWORD: {db_password}")
    print(f"DB_NAME: {db_name}")    
    print(f"DB_HOST: {db_host}")

    conn = None
    try:
        # Connect to the PostgreSQL database
        conn = psycopg2.connect(
            host=db_host,
            database=db_name,
            user=db_user,
            password=db_password,
            port=db_port
        )
        
        # Create a cursor with RealDictCursor to return results as dictionaries
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Sample read operation - modify the query as needed
        cursor.execute("SELECT * FROM users LIMIT 10")
        results = cursor.fetchall()
        
        # Sample write operation - modify as needed
        # Uncomment to use write operations
        # sample_user = ("john_doe", "John", "Doe", "john@example.com")
        # cursor.execute(
        #     "INSERT INTO users (username, first_name, last_name, email) VALUES (%s, %s, %s, %s) RETURNING id",
        #     sample_user
        # )
        # new_user_id = cursor.fetchone()['id']
        # conn.commit()
        
        # Convert results to a list of dictionaries
        result_list = [dict(row) for row in results]
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Database operation successful',
                'data': result_list
                # Uncomment for write operations
                # 'newUserId': new_user_id
            }, default=str)  # default=str handles dates and other non-serializable types
        }
        
    except Exception as e:
        print(f"Database error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Database operation failed',
                'error': str(e)
            })
        }
        
    finally:
        if conn:
            conn.close()
    # # Create connection string
    # connection_string = f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
    
    # try:
    #     # Create engine
    #     engine = create_engine(connection_string)
        
    #     # Execute a test query
    #     with engine.connect() as connection:
    #         result = connection.execute(text("SELECT * FROM users LIMIT 10"))
    #         rows = [dict(row) for row in result]
        
    #     return {
    #         'statusCode': 200,
    #         'body': json.dumps(rows, default=str)  # default=str helps with datetime serialization
    #     }
    
    # except SQLAlchemyError as e:
    #     print(f"Database error: {str(e)}")
    #     return {
    #         'statusCode': 500,
    #         'body': json.dumps({'error': 'Database connection failed'})
    #     }


    # return {
    #     'statusCode': 200,
    #     'body': json.dumps('Hello from S3 Lambda v2!')
    # }


if __name__ == "__main__":
    # Mock event and context
    mock_event = {}  # You can add any test data here if needed
    class MockContext:
        def __init__(self):
            self.function_name = "test_lambda"
            self.memory_limit_in_mb = 128
            self.invoked_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:test_lambda"
            self.aws_request_id = "test-invoke-request"

    mock_context = MockContext()

    # Call the handler
    response = lambda_handler(mock_event, mock_context)
    print("Lambda response:")
    print(json.dumps(response, indent=2))
