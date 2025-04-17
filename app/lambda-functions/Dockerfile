# Start from lambda Python3.8 image
FROM public.ecr.aws/lambda/python:3.9


# Install postgresql-devel in your image
RUN yum install -y gcc postgresql-devel

# Copy requirements and install
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy function code
COPY lambda_function.py .

# Command for AWS Lambda
CMD ["lambda_function.lambda_handler"]
