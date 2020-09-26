require "../../spec_helper"

describe Granite::Migrator do
  describe "#drop_sql" do
    it "generates correct SQL with #{{{ env("CURRENT_ADAPTER") }}} adapter" do
      {% if env("CURRENT_ADAPTER") == "mysql" %}
        Review.migrator.drop_sql.should eq "DROP TABLE IF EXISTS `reviews`;"
      {% else %}
        Review.migrator.drop_sql.should eq "DROP TABLE IF EXISTS \"reviews\";"
      {% end %}
    end
  end

  describe "#create_sql" do
    it "generates correct SQL with #{{{ env("CURRENT_ADAPTER") }}} adapter" do
      {% if env("CURRENT_ADAPTER") == "pg" %}
        Review.migrator.create_sql.should eq <<-SQL
          CREATE TABLE "reviews"(
          "id" BIGSERIAL PRIMARY KEY,
          "name" TEXT
          ,
          "downvotes" INT
          ,
          "upvotes" BIGINT
          ,
          "sentiment" REAL
          ,
          "interest" DOUBLE PRECISION
          ,
          "published" BOOL
          ,
          "created_at" TIMESTAMP
          ) ;\n
          SQL

        Kvs.migrator.create_sql.should eq <<-SQL
          CREATE TABLE "kvs"(
          "k" TEXT PRIMARY KEY,
          "v" TEXT
          ) ;\n
          SQL

        UUIDModel.migrator.create_sql.should eq <<-SQL
          CREATE TABLE "uuids"(
          "uuid" UUID PRIMARY KEY) ;\n
          SQL

        Character.migrator.create_sql.should eq <<-SQL
          CREATE TABLE "characters"(
          "character_id" SERIAL PRIMARY KEY,
          "name" TEXT NOT NULL
          ) ;\n
          SQL

        # Also check Array types for pg
        ArrayModel.migrator.create_sql.should eq <<-SQL
          CREATE TABLE "array_model"(
          "id" SERIAL PRIMARY KEY,
          "str_array" TEXT[]
          ,
          "i16_array" SMALLINT[]
          ,
          "i32_array" INT[]
          ,
          "i64_array" BIGINT[]
          ,
          "f32_array" REAL[]
          ,
          "f64_array" DOUBLE PRECISION[]
          ,
          "bool_array" BOOLEAN[]
          ) ;\n
          SQL
      {% elsif env("CURRENT_ADAPTER") == "mysql" %}
        Review.migrator.create_sql.should eq <<-SQL
          CREATE TABLE `reviews`(
          `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
          `name` VARCHAR(255)
          ,
          `downvotes` INT
          ,
          `upvotes` BIGINT
          ,
          `sentiment` FLOAT
          ,
          `interest` DOUBLE
          ,
          `published` BOOL
          ,
          `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          ) ;\n
          SQL

        Kvs.migrator.create_sql.should eq <<-SQL
          CREATE TABLE `kvs`(
          `k` VARCHAR(255) PRIMARY KEY,
          `v` VARCHAR(255)
          ) ;\n
          SQL

        Character.migrator.create_sql.should eq <<-SQL
          CREATE TABLE `characters`(
          `character_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
          `name` VARCHAR(255) NOT NULL
          ) ;\n
          SQL

        UUIDModel.migrator.create_sql.should eq <<-SQL
          CREATE TABLE `uuids`(
          `uuid` CHAR(36) PRIMARY KEY) ;\n
          SQL
      {% elsif env("CURRENT_ADAPTER") == "sqlite" %}
        Review.migrator.create_sql.should eq <<-SQL
          CREATE TABLE "reviews"(
          "id" INTEGER NOT NULL PRIMARY KEY,
          "name" VARCHAR(255)
          ,
          "downvotes" INTEGER
          ,
          "upvotes" INTEGER
          ,
          "sentiment" FLOAT
          ,
          "interest" REAL
          ,
          "published" BOOL
          ,
          "created_at" VARCHAR
          ) ;\n
          SQL

        Kvs.migrator.create_sql.should eq <<-SQL
          CREATE TABLE "kvs"(
          "k" VARCHAR(255) PRIMARY KEY,
          "v" VARCHAR(255)
          ) ;\n
          SQL

        Character.migrator.create_sql.should eq <<-SQL
          CREATE TABLE "characters"(
          "character_id" INTEGER NOT NULL PRIMARY KEY,
          "name" VARCHAR(255) NOT NULL
          ) ;\n
          SQL

        UUIDModel.migrator.create_sql.should eq <<-SQL
          CREATE TABLE "uuids"(
          "uuid" CHAR(36) PRIMARY KEY) ;\n
          SQL
      {% end %}
    end

    it "supports a manually supplied column type" do
      {% if env("CURRENT_ADAPTER") == "pg" %}
        ManualColumnType.migrator.create_sql.should eq <<-SQL
          CREATE TABLE "manual_column_types"(
          "id" BIGSERIAL PRIMARY KEY,
          "foo" DECIMAL(12, 10)
          ) ;\n
          SQL
      {% elsif env("CURRENT_ADAPTER") == "mysql" %}
        ManualColumnType.migrator.create_sql.should eq <<-SQL
          CREATE TABLE `manual_column_types`(
          `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
          `foo` DECIMAL(12, 10)
          ) ;\n
          SQL
      {% elsif env("CURRENT_ADAPTER") == "sqlite" %}
        ManualColumnType.migrator.create_sql.should eq <<-SQL
          CREATE TABLE "manual_column_types"(
          "id" INTEGER NOT NULL PRIMARY KEY,
          "foo" DECIMAL(12, 10)
          ) ;\n
          SQL
      {% end %}
    end
  end
end
