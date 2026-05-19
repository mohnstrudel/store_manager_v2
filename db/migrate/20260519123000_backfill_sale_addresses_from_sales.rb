# frozen_string_literal: true

class BackfillSaleAddressesFromSales < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      INSERT INTO sale_addresses (
        sale_id,
        kind,
        first_name,
        last_name,
        email,
        phone,
        company,
        address_1,
        address_2,
        city,
        state,
        postcode,
        country,
        created_at,
        updated_at
      )
      SELECT
        sales.id,
        0,
        customers.first_name,
        customers.last_name,
        customers.email,
        customers.phone,
        sales.company,
        sales.address_1,
        sales.address_2,
        sales.city,
        sales.state,
        sales.postcode,
        sales.country,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      FROM sales
      INNER JOIN customers ON customers.id = sales.customer_id
      WHERE NOT EXISTS (
        SELECT 1
        FROM sale_addresses
        WHERE sale_addresses.sale_id = sales.id
          AND sale_addresses.kind = 0
      )
        AND COALESCE(
          NULLIF(sales.address_1, ''),
          NULLIF(sales.address_2, ''),
          NULLIF(sales.city, ''),
          NULLIF(sales.company, ''),
          NULLIF(sales.country, ''),
          NULLIF(sales.postcode, ''),
          NULLIF(sales.state, '')
        ) IS NOT NULL
    SQL
  end

  def down
    # Historical address snapshots should be kept once created.
  end
end
