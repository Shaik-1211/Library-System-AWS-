use aws_config::meta::region::RegionProviderChain;
use aws_sdk_dynamodb::{Client, Error, Region, PKG_VERSION};
// suse structopt::StructOpt;
use tokio_stream::StreamExt;

// #[derive(Debug, StructOpt)]
// struct Opt {
//     /// The AWS Region.
//     #[structopt(short, long)]
//     region: Option<String>,

//     /// The name of the table.
//     #[structopt(short, long)]
//     table: String,

//     /// Whether to display additional information.
//     #[structopt(short, long)]
//     verbose: bool,
// }

// Lists the items in a table.
// snippet-start:[dynamodb.rust.list-items]
pub async fn list_items(client: &Client, table: &str) -> Result<(), Error> {
    let items: Result<Vec<_>, _> = client
        .scan()
        .table_name(table)
        .into_paginator()
        .items()
        .send()
        .collect()
        .await;

    println!("Items in table:");
    for item in items? {
        println!("   {:?}", item);
    }

    Ok(())
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    tracing_subscriber::fmt::init();

    let Opt {
        table,
        region,
        verbose,
    } = Opt::from_args();

    let region_provider = RegionProviderChain::first_try(region.map(Region::new))
        .or_default_provider()
        .or_else(Region::new("us-west-2"));
    println!();

    if verbose {
        println!("DynamoDB client version: {}", PKG_VERSION);
        println!(
            "Region:                  {}",
            region_provider.region().await.unwrap().as_ref()
        );
        println!("Table:                   {}", &table);

        println!();
    }

    let shared_config = aws_config::from_env().region(region_provider).load().await;
    let client = Client::new(&shared_config);

    list_items(&client, &table).await
}