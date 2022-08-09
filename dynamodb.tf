/* resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "Library"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "Book-Name"
  /* range_key      = "Type" */

  attribute {
    name = "book-name"
    type = "String"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  /* global_secondary_index {
    name               = "Type"
    hash_key           = "GameTitle"
    range_key          = "TopScore"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["UserId"]
  } */

  tags = {
    Name        = "Library-Table"
    Environment = "production"
  }
}
 */
