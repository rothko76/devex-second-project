# devex-second-project
Advanced Scalable E-commerce Web Application with Real-Time Streaming, Security, Autoscaling, and Helm on AWS



- Setup

#### Backend infra setup
{project_root}/infrastructure/terraform_backend/

```terraform apply```

will setup:
- S3 bucket for keeping terraform state  
- DynamoDB table to manage the state lock

#### Main infra setup
```terraform destroy```

#### Backend infra
Before running make sure to empty the state bucked (manully)
```terraform apply```



#### Deploying the flask app on the EKS cluster



Teardown

#### Main setup


#### 


Core API Endpoints
Products

GET /api/products - List all products with pagination
GET /api/products/{id} - Get product details
POST /api/products - Add new product
PUT /api/products/{id} - Update product
DELETE /api/products/{id} - Remove product
GET /api/products/search - Search products (using Elasticsearch)

Users

POST /api/users/register - Register new user
POST /api/users/login - User login
GET /api/users/profile - Get user profile
PUT /api/users/profile - Update user profile

Cart

GET /api/cart - View cart
POST /api/cart/items - Add item to cart
PUT /api/cart/items/{id} - Update cart item
DELETE /api/cart/items/{id} - Remove item from cart

Orders

POST /api/orders - Create order from cart
GET /api/orders - List user orders
GET /api/orders/{id} - Get order details
