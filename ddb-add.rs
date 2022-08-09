
use aws_config::meta::region::RegionProviderChain;
use aws_sdk_dynamodb::model::AttributeValue;
use aws_sdk_dynamodb::{Client, Error, Region, PKG_VERSION};
use std::process;
use structopt::StructOpt;

#[derive(Debug, StructOpt)]
struct Opt {
    #[structopt(short,long)]
    book-name:String,

    #[structopt(short, long)]
    table: String,

    #[structopt(short, long)]
    region: Option<String>,

    #[structopt(short, long)]
    verbose: bool,
}

async fn add_item(
    client: &Client,
    table: &str,
    book:&str
) -> Result<(), Error> {
    let book_av = AttributeValue::S(book.into());

    let request = client
        .put_item()
        .table_name(table)
        .item("book-name", book_av);

    println!("Executing request [{:?}] to add item...", request);

    request.send().await?;

    println!("Added book {} to table {}",book, table);

    Ok(())
}

#[tokio::main]
pub async fn main() -> Result<(), Error> {
    let Opt {
        table,
        book-name,
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
        println!("Table:  {}", table);
        println!();
    }

    let shared_config = aws_config::from_env().region(region_provider).load().await;
    let client = Client::new(&shared_config);

    add_item(&client, &table, &book-name).await
}