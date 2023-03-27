resource "aws_dynamodb_table" "library-ddb-table" {
  name         = "Library"
  billing_mode = "PAY_PER_REQUEST"
  #   read_capacity  = 20
  #   write_capacity = 20
  hash_key  = "BookId"
  /* range_key = "BookName" */

  attribute {
    name = "BookId"
    type = "S"
  }

  attribute {
    name = "BookName"
    type = "S"
  }

  attribute {
    name = "Author"
    type = "S"
  }

  #   ttl {
  #     attribute_name = "TimeToExist"
  #     enabled        = false
  #   }

  global_secondary_index {
    name               = "BookId"
    hash_key           = "BookName"
    range_key          = "Author"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["Author"]
  }

  tags = {
    Name        = "Library-Default-Shelf"
    Environment = "spike"
  }
}