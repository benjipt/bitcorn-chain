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
    execute <<-SQL
      DROP TABLE transactions;
      DROP TABLE addresses;
    SQL
  end
end
