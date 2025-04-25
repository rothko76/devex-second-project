import json
import os
import json
import psycopg2
from psycopg2.extras import RealDictCursor
import base64
import logging


# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda function to process product data from Kinesis stream and write to PostgreSQL
    """
    # Get database connection parameters from environment variables
    db_host = os.environ.get('DB_HOST')
    db_name = os.environ.get('DB_NAME')
    db_user = os.environ.get('DB_USER')
    db_password = os.environ.get('DB_PASSWORD')
    db_port = os.environ.get('DB_PORT', '5432')

    
    # Process each record from the Kinesis stream
    # for record in event['Records']:
    #     try:
    #         # Debug the incoming data
    #         kinesis_data = record['kinesis']['data']
    #         logger.info(f"Raw Kinesis data: {kinesis_data[:30]}...")
            
    #         # Try to decode the base64 data
    #         try:
    #             decoded_data = base64.b64decode(kinesis_data)
    #             logger.info(f"Successfully decoded base64 data, length: {len(decoded_data)}")
                
    #             # Try to parse as JSON
    #             try:
    #                 message = json.loads(decoded_data)
    #                 logger.info("Successfully parsed JSON data")
                    
    #                 # Extract metadata and validate event type
    #                 event_type = message.get('metadata', {}).get('event_type')
    #                 logger.info(f"Event type: {event_type}")
                    
    #                 if event_type in ['product_created', 'product_updated']:
    #                     product_data = message.get('data', {})
    #                     process_product(product_data, db_host, db_name, db_user, db_password, db_port)
    #                 else:
    #                     logger.info(f"Ignoring event type: {event_type}")
                        
    #             except json.JSONDecodeError as e:
    #                 logger.error(f"Failed to parse JSON: {e}")
    #                 # Try to print the raw data for debugging
    #                 try:
    #                     logger.info(f"Raw decoded content: {decoded_data[:100]}...")
    #                 except:
    #                     logger.info("Could not display raw decoded content")
            
    #         except UnicodeDecodeError as e:
    #             logger.error(f"Unicode decode error: {e}")
    #             # Try alternative decoding or handle the error
    #             try:
    #                 # Try Latin-1 encoding which accepts any byte value
    #                 message_str = decoded_data.decode('latin-1')
    #                 logger.info(f"Decoded with latin-1: {message_str[:100]}...")
    #                 message = json.loads(message_str)
    #                 event_type = message.get('metadata', {}).get('event_type')
    #                 if event_type in ['product_created', 'product_updated']:
    #                     product_data = message.get('data', {})
    #                     process_product(product_data, db_host, db_name, db_user, db_password, db_port)
    #                     print(f"Processed product data: {product_data}")
    #             except Exception as e2:
    #                 logger.error(f"Alternative decoding failed: {e2}")
        
    #     except Exception as e:
    #         logger.error(f"Error processing record: {e}")
    
    # return {
    #     'statusCode': 200,
    #     'body': json.dumps('Processing completed')
    # }

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
        cursor.execute("""
            INSERT INTO public.products 
            ("name", description, price, stock_quantity, category_id, sku, image_url, is_active)
            VALUES 
            (
              'Wireless Mouse',
              'Ergonomic wireless mouse with adjustable DPI',
              25.99,
              100,
              1,
              'WM-001',
              'https://example.com/images/mouse.jpg',
              true
            )
            ON CONFLICT (sku) DO UPDATE
            SET 
              "name" = EXCLUDED.name,
              description = EXCLUDED.description,
              price = EXCLUDED.price,
              stock_quantity = EXCLUDED.stock_quantity,
              category_id = EXCLUDED.category_id,
              image_url = EXCLUDED.image_url,
              is_active = EXCLUDED.is_active,
              updated_at = CURRENT_TIMESTAMP
            RETURNING product_id;
        """)
        product_id = cursor.fetchone()['product_id']
        conn.commit()
        print(f"Inserted/Updated product with ID: {product_id}")
      
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
        # result_list = [dict(row) for row in results]
        
        # return {
        #     'statusCode': 200,
        #     'body': json.dumps({
        #         'message': 'Database operation successful',
        #         'data': result_list
        #         # Uncomment for write operations
        #         # 'newUserId': new_user_id
        #     }, default=str)  # default=str handles dates and other non-serializable types
        # }
        
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
