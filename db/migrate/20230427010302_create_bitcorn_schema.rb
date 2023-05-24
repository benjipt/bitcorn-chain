# This migration creates the bitcorn schema for the application.
# It defines two tables: `addresses` and `transactions`.
#
# The `addresses` table represents Bitcorn addresses and contains the following columns:
# * `address`: the unique identifier of the address. It is the primary key of the table.
# * `cornlet_balance`: the balance of Cornlets for the address. It cannot be less than 0.
# * `created_at` and `updated_at`: timestamps for record creation and last update.
#
# The `transactions` table represents transactions between addresses and contains the following columns:
# * `id`: the unique identifier of the transaction. It is the primary key of the table.
# * `from_address` and `to_address`: the sender's and recipient's addresses.
#   These are foreign keys that reference the `address` column in the `addresses` table.
# * `cornlet_amount`: the amount of Cornlets being transferred. It must be greater than 0.
# * `created_at`: timestamp for the transaction's creation.
#
# In the `up` method, these tables are created with their columns and constraints.
# In the `down` method, these tables are dropped, effectively rolling back the migration.
class CreateBitcornSchema < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      -- Create the addresses table
      CREATE TABLE addresses (
        address VARCHAR(255) PRIMARY KEY NOT NULL UNIQUE,
        cornlet_balance BIGINT NOT NULL DEFAULT 0,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
        CONSTRAINT valid_balance CHECK (cornlet_balance >= 0)
      );

      -- Create the transactions table
      CREATE TABLE transactions (
          id SERIAL PRIMARY KEY NOT NULL UNIQUE,
          from_address VARCHAR(255) NOT NULL,
          to_address VARCHAR(255) NOT NULL,
          cornlet_amount INTEGER NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
          FOREIGN KEY (from_address) REFERENCES addresses(address),
          FOREIGN KEY (to_address) REFERENCES addresses(address),
          CONSTRAINT valid_amount CHECK (cornlet_amount > 0)
      );
    SQL
  end

  def down
    execute <<-SQL.squish
      DROP TABLE transactions;
      DROP TABLE addresses;
    SQL
  end
end
