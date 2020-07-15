require "../../spec_helper"
{% begin %}
  {% adapter_literal = env("CURRENT_ADAPTER").id %}
  class AllFields < Granite::Migration
    connection :{{ adapter_literal }}

    def up
      create_table :posts do |t|
        t.primary :id
        t.serial :serial1
        t.bigserial :bigserial1
        t.uuid :uuid1
        t.password :string1
        t.string :string2
        t.text :string3
        t.bool :bool1
        t.boolean :boolean2
        t.ref :ref1
        t.reference :ref2
        t.int :int1
        t.integer :int2
        t.bigint :bigint1
        t.biginteger :bigint2
        t.float :float1
        t.real :real1
        t.time :time1
        t.timestamp :time2
      end
    end

    def down
      drop_table :posts
    end
  end
{% end %}

describe Granite::Migration do
  describe "create_table" do
    it "generates create table sql for all fields" do
      {% if env("CURRENT_ADAPTER") == "pg" %}
        AllFields.new.generate_sql(:up).should eq <<-SQL
        CREATE TABLE "posts" (id BIGSERIAL PRIMARY KEY, serial1 SERIAL, bigserial1 BIGSERIAL, uuid1 UUID, string1 TEXT, string2 TEXT, string3 TEXT, bool1 BOOL, boolean2 BOOL, ref1 BIGINT, ref2 BIGINT, int1 INT, int2 INT, bigint1 BIGINT, bigint2 BIGINT, float1 REAL, real1 DOUBLE PRECISION, time1 TIMESTAMP, time2 TIMESTAMP);
        SQL
      {% end %}
      {% if env("CURRENT_ADAPTER") == "mysql" %}
        AllFields.new.generate_sql(:up).should eq <<-SQL
        CREATE TABLE "posts" (id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, serial1 INT NOT NULL AUTO_INCREMENT, bigserial1 BIGINT NOT NULL AUTO_INCREMENT, uuid1 CHAR(36), string1 VARCHAR(255), string2 VARCHAR(255), string3 VARCHAR(255), bool1 BOOL, boolean2 BOOL, ref1 BIGINT, ref2 BIGINT, int1 INT, int2 INT, bigint1 BIGINT, bigint2 BIGINT, float1 FLOAT, real1 DOUBLE, time1 TIMESTAMP, time2 TIMESTAMP);
        SQL
      {% end %}
      {% if env("CURRENT_ADAPTER") == "sqlite" %}
        AllFields.new.generate_sql(:up).should eq <<-SQL
        CREATE TABLE "posts" (id INTEGER NOT NULL PRIMARY KEY, serial1 INTEGER NOT NULL, bigserial1 INTEGER NOT NULL, uuid1 CHAR(36), string1 VARCHAR(255), string2 VARCHAR(255), string3 VARCHAR(255), bool1 BOOL, boolean2 BOOL, ref1 INTEGER, ref2 INTEGER, int1 INTEGER, int2 INTEGER, bigint1 INTEGER, bigint2 INTEGER, float1 FLOAT, real1 REAL, time1 TIMESTAMP, time2 TIMESTAMP);
        SQL
      {% end %}
    end
  end

  describe "rename_table" do
    it "generates alter table sql" do
      AllFields.new.rename_table(:old_posts, :new_posts).should eq [<<-SQL
      ALTER TABLE "old_posts" RENAME TO "new_posts"
      SQL
      ]
    end
  end

  describe "drop_table" do
    it "generates drop table sql" do
      AllFields.new.generate_sql(:down).should eq <<-SQL
      DROP TABLE IF EXISTS "posts";
      SQL
    end
  end

  describe "create_index" do
    it "generates create index sql" do
      AllFields.new.create_index(:posts, :user_id).should eq [<<-SQL
      CREATE INDEX "posts-user_id-idx" ON "posts" (user_id)
      SQL
      ]
    end

    it "generates create index sql for multiple fields" do
      AllFields.new.create_index(:posts, [:user_id, :name]).should eq [<<-SQL
      CREATE INDEX "posts-user_id-name-idx" ON "posts" (user_id, name)
      SQL
      ]
    end
  end

  describe "drop_index" do
    it "generates drop index sql" do
      AllFields.new.drop_index(:posts, :user_id).should eq [<<-SQL
      DROP INDEX "posts-user_id-idx"
      SQL
      ]
    end

    it "generates drop index sql for multiple fields" do
      AllFields.new.drop_index(:posts, [:user_id, :name]).should eq [<<-SQL
      DROP INDEX "posts-user_id-name-idx"
      SQL
      ]
    end
  end

  describe "add_column" do
    it "generates alter table sql to add column" do
      {% if env("CURRENT_ADAPTER") == "pg" %}
        AllFields.new.add_column(:posts, :col, :integer).should eq [<<-SQL
        ALTER TABLE "posts" ADD COLUMN "col" INT
        SQL
        ]
      {% end %}
      {% if env("CURRENT_ADAPTER") == "mysql" %}
        AllFields.new.add_column(:posts, :col, :integer).should eq [<<-SQL
        ALTER TABLE "posts" ADD COLUMN "col" INT
        SQL
        ]
      {% end %}
      {% if env("CURRENT_ADAPTER") == "sqlite" %}
        AllFields.new.add_column(:posts, :col, :integer).should eq [<<-SQL
        ALTER TABLE "posts" ADD COLUMN "col" INTEGER
        SQL
        ]
      {% end %}
    end
  end

  describe "rename_column" do
    it "generates alter table sql to rename column" do
      AllFields.new.rename_column(:posts, :old_col, :new_col).should eq [<<-SQL
      ALTER TABLE "posts" RENAME COLUMN "old_col" TO "new_col"
      SQL
      ]
    end
  end

  describe "remove_column" do
    it "generates alter table sql to remove column" do
      AllFields.new.remove_column(:posts, :col).should eq [<<-SQL
      ALTER TABLE "posts" DROP COLUMN "col"
      SQL
      ]
    end
  end
end
