use aws_sdk_dynamodb::{model::AttributeValue, Client, Error};
use lambda_runtime::{service_fn, LambdaEvent};
use serde::{Deserialize, Serialize};
use serde_json::{json, Map, Value};
use tracing_subscriber::EnvFilter;

const TABLE: &str = "Library";
#[derive(Deserialize, Serialize)]
struct Request {
    method: String,
    path: String,
}

#[derive(Deserialize, Serialize)]
struct Table {
    book_id: String,
    book_name: String,
}

#[derive(Deserialize, Serialize)]
struct Status {
    msg: String,
}

impl Status {
    fn new(msg: &str) -> Status {
        Status {
            msg: msg.to_string()
        }
    }
}

enum Response {
    Tables(Vec<Table>),
    Msg(Status),
}

impl Response {
    fn get_string(&self) -> Result<String, Error> {
        let result = match self {
            Response::Tables(tables) => serde_json::to_string(tables).unwrap(),
            Response::Msg(status )=> serde_json::to_string(status).unwrap(),
        };
        Ok(result)
    }
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    init_lambda_tracing();
    let func = service_fn(func);
    lambda_runtime::run(func).await;
    Ok(())
}

fn init_lambda_tracing() {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .without_time()
        .init();
}

async fn func(event: LambdaEvent<Value>) -> Result<Value, Error> {
    let payload = event.payload;
    let req: Request = Request {
        method: get_method(&payload),
        path: get_path(&payload),
    };
    let client: Client = get_client().await?;
  
    let response: Response = match req.path.as_str() {
        "/" => match req.method.as_str() {
            "GET" => {
                let books = get_books(&client).await;
                if let Ok(books_list) = books {
                    Response::Tables(books_list)
                } else {
                    Response::Msg(Status::new("failed to get the table content!"))
                }
            }
            "POST" => {
                let body_str = payload["body"].as_str().unwrap();
                let body:Map<String,Value>= serde_json::from_str(&body_str).unwrap();
                let result = push_book(&client, &body).await;
                if result.is_ok() {
                    Response::Msg(Status::new("successfully pushed the data into dynamodb!"))
                } else {
                    Response::Msg(Status::new("Failed to push the data into dynamodb!"))
                }
            }
            "PUT" => Response::Msg(Status::new("put not implemented")),
            "DELETE" => {
                let body_str = payload["body"].as_str().unwrap();
                let body:Map<String,Value>= serde_json::from_str(&body_str).unwrap();
                let result = delete_book(&client, &body).await;
                if result.is_ok() {
                    Response::Msg(Status::new("successfully deleted the item from dynamodb!"))
                } else {
                    Response::Msg(Status::new("Failed to delete the item into dynamodb!"))
                }
            },
            "OPTIONS" => {
                let headers = "Options method";
                Response::Msg(Status::new(headers))
            }
            _ =>Response::Msg(Status::new("Method not implemented")),
        },
        _ => Response::Msg(Status::new("Unknown path")),
    };
    Ok(json!({
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "*",
            "Access-Control-Allow-Methods": "*",
        },
        "body":  response.get_string()?,
    }))
}

fn get_method(event: &Value) -> String {
    let method = event["httpMethod"].as_str().unwrap();
    method.to_string()
}

fn get_path(event: &Value) -> String {
    let path = event["path"].as_str().unwrap();
    path.to_string()
}

async fn get_client() -> Result<Client, Error> {
    let shared_config = aws_config::load_from_env().await;
    Ok(Client::new(&shared_config))
}

async fn get_books(client: &Client) -> Result<Vec<Table>, Error> {
    let request = client.scan().table_name(TABLE).send().await?;
    let mut response = Vec::new();
    if let Some(items) = request.items {
        for item in items {
            response.push(Table {
                book_id: item.get("BookId").unwrap().as_s().unwrap().to_string(),
                book_name: item.get("BookName").unwrap().as_s().unwrap().to_string(),
            });
        }
    }
    Ok(response)
}

async fn push_book(client: &Client, data: &Map<String, Value>) -> Result<(), Error> {
    let book_id = data.get("bookId").unwrap().as_str().unwrap();
    let book_name = data.get("bookName").unwrap().as_str().unwrap();
    let request = client
        .put_item()
        .table_name(TABLE)
        .item("BookId", AttributeValue::S(book_id.into()))
        .item("BookName", AttributeValue::S(book_name.into()));
    request.send().await?;
    Ok(())
}

async fn delete_book(client: &Client, data: &Map<String, Value>) -> Result<(), Error> {
    let book_id = data.get("bookId").unwrap().as_str().unwrap();
    let request = client 
        .delete_item()
        .table_name(TABLE)
        .key("BookId", AttributeValue::S(book_id.into()));
    request.send().await?;
    Ok(())
}



