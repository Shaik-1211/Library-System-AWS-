// use lambda_runtime::{service_fn, LambdaEvent, Error};
// use serde_json::{json, Value};
// use tracing_subscriber::EnvFilter;
// // use tracing::info;
// use aws_config::meta::region::RegionProviderChain;
// use aws_sdk_dynamodb::{Client, Region, PKG_VERSION};
// use structopt::StructOpt;
// use tokio_stream::StreamExt;
// use aws_sdk_dynamodb::model::AttributeValue;

// #[derive(Debug, StructOpt)]
// struct Opt {
//     /// The AWS Region.
//     #[structopt(short, long)]
//     region: Option<String>,
// }
// #[tokio::main]
// async fn main() -> Result<(), Error> {
//     init_lambda_tracing();
//     let func = service_fn(my_handler);
//     lambda_runtime::run(func).await?;
//     Ok(())
// }

// fn init_lambda_tracing() {
//     tracing_subscriber::fmt()
//         .with_env_filter(EnvFilter::from_default_env())
//         .without_time()
//         .init();
// }

// async fn my_handler(event: LambdaEvent<Value>) -> Result<Value, Error> {
//     // let (event,_context) = event.into_parts();
//     // let new_book = event["new_book"].as_str().unwrap();
//     // println!("{:?}",new_book);
//     let mut resp = vec![
//         "Atomic Habits",
//         "Wings of Fire",
//         "Rich Dad Poor Dad",
//         "Think and Grow Rich",
//         "Do Epic Shit",
//         "Power of SubConscious Mind",
//         "Geography"
//     ];

//     // resp.push(new_book);
//     // resp.push("A new book added");
//     let items = config_ddb();
//     Ok(json!({
//         "statusCode" : 200,
//         "headers" : {
//             "Content-Type": "application/json",
//         "Access-Control-Allow-Origin": "*",
//         "Access-Control-Allow-Headers": "*",
//         "Access-Control-Allow-Methods": "*",
//         },
//         "body": serde_json::to_string( &resp)?,
//     }))
// }

// async fn config_ddb()->Result<Vec<String>, Error>{
//     // let reg = String::from("us-west-2");
    
//     // let region= Opt{
//     //     region:Some(reg),
//     // };
//     // let region_provider = RegionProviderChain::first_try(region.map(Region::new))
//     //     .or_default_provider()
//     //     .or_else(Region::new("us-west-2"));

//     // let shared_config = aws_config::from_env().region(region_provider).load().await;
//     // let client = Client::new(&shared_config);   

//     let config = aws_config::load_from_env().await;
//     let client = aws_sdk_dynamodb::Client::new(&config);

//     let resut = list_items(&client,"Library");
//     Ok(resut)
// }

// pub async fn list_items(client: &Client, table: &str) -> Result<Vec<String>, Error> {
//     let items: Result<Vec<_>, _> = client
//         .scan()
//         .table_name(table)
//         .into_paginator()
//         .items()
//         .send()
//         .collect()
//         .await;
//     let mut values = vec![];
//     println!("Items in table:");
//     for item in items? {
//         for (i,j) in item{
//             let val = i.clone();
//             values.push(val);
//         }
//         // println!("   {:?}", item);
//     }

//     Ok(values)
// }

/**************************************************************** */

use lambda_runtime::{service_fn, LambdaEvent, Error};
use serde_json::{json, Value};
use tracing_subscriber::EnvFilter;
// use tracing::info;
use aws_config::meta::region::RegionProviderChain;
use aws_sdk_dynamodb::{Client, Region, PKG_VERSION};
use structopt::StructOpt;
use tokio_stream::StreamExt;
use aws_sdk_dynamodb::model::AttributeValue;

#[derive(Debug, StructOpt)]
struct Opt {
    /// The AWS Region.
    #[structopt(short, long)]
    region: Option<String>,
}
#[tokio::main]
async fn main() -> Result<(), Error> {
    init_lambda_tracing();
    let func = service_fn(my_handler);
    lambda_runtime::run(func).await?;
    Ok(())
}

fn init_lambda_tracing() {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .without_time()
        .init();
}

async fn my_handler(event: LambdaEvent<Value>) -> Result<Value, Error> {
    // let (event,_context) = event.into_parts();
    // let new_book = event["new_book"].as_str().unwrap();
    // println!("{:?}",new_book);
    // let mut resp = vec![
    //     "Atomic Habits",
    //     "Wings of Fire",
    //     "Rich Dad Poor Dad",
    //     "Think and Grow Rich",
    //     "Do Epic Shit",
    //     "Power of SubConscious Mind",
    //     "Geography"
    // ];

    // resp.push(new_book);
    // resp.push("A new book added");

    let config = aws_config::load_from_env().await;
    let client = aws_sdk_dynamodb::Client::new(&config);

    let items: Result<Vec<_>, _> = client
    .scan()
    .table_name("Library")
    .into_paginator()
    .items()
    .send()
    .collect()
    .await;
    let mut values = vec![];
    for item in items{
        for val in item{
            for (key, value) in val{
                match value{
                    AttributeValue::S(s)=>{
                        values.push(s.clone())
                    }
                    _ => todo!()
                }
            }

        }
    }
    let items = config_ddb();
    Ok(json!({
        "statusCode" : 200,
        "headers" : {
            "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "*",
        "Access-Control-Allow-Methods": "*",
        },
        "body": serde_json::to_string( &values)?,
    }))
}