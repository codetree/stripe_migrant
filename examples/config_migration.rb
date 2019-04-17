require 'dotenv'
require 'stripe'
require 'stripe_migrant'

Dotenv.load

target_key = ENV['STRIPE_NEW_SK']
source_key = ENV['STRIPE_OLD_SK']

migrator = StripeMigrant::Migrator.new(source_key: source_key, target_key: target_key)

puts 'Migrating Products, Plans, and Coupons'

# migrate products
products = migrator.get_products(api_key: source_key)
migrator.update_products(api_key: target_key, products: products)

# migrate plans
plans = migrator.get_plans(api_key: source_key)
migrator.update_plans(api_key: target_key, plans: plans)

# migrate coupons
coupons = migrator.get_coupons(api_key: source_key)
migrator.update_coupons(api_key: target_key, coupons: coupons)
