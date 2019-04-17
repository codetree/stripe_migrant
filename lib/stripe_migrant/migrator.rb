# frozen_string_literal: true

require 'logger'

module StripeMigrant
  class Migrator
    def initialize(source_key:, target_key:, output_file: STDOUT, log_level: Logger::DEBUG)
      @source_key = source_key
      @target_key = target_key
      @logger = Logger.new(output_file)
      @logger.level = log_level
      Stripe.set_app_info(
        'StripeMigrant',
        version: StripeMigrant::VERSION,
        url: 'https://www.github.com/codetree/stripe_migrant'
      )
    end

    def get_coupons(api_key:, limit: 100)
      Stripe.api_key = api_key
      Stripe::Coupon.all(limit: limit)
    end

    def get_customers(api_key:, starting_after: nil)
      Stripe.api_key = api_key
      limit = 100
      more_customers = true
      count = 0
      customers = []
      after = starting_after

      while more_customers
        count += 1
        @logger.info "getting page #{count} of customers"
        c = Stripe::Customer.all({ limit: limit, starting_after: after }.compact).data
        customers += c
        after = c.last
        more_customers = (c.count == limit)
      end
      customers
    end

    def get_products(api_key:, limit: 100)
      Stripe.api_key = api_key
      Stripe::Product.all(limit: limit)
    end

    def get_plans(api_key:, limit: 100)
      Stripe.api_key = api_key
      Stripe::Plan.all(limit: limit)
    end

    def cancel_confirmed_subscriptions
      subs = sub_migrator.get_all
      confirmed_subs = sub_migrator.confirm_all(subscriptions: subs)
      @logger.info "Confirmed subscriptions: #{confirmed_subs.count}"
      sub_migrator.cancel_all(subscriptions: confirmed_subs)
    end

    def migrate_subscriptions
      subs = sub_migrator.get_all
      @logger.info "Subscriptions to be migrated: #{subs.count}"
      sub_migrator.create_all(subscriptions: subs)
    end

    def update_coupons(api_key:, coupons:)
      @logger.info "UPDATING COUPONS IN #{api_key}"
      Stripe.api_key = api_key

      coupons.each do |c|
        begin
          @logger.info "Retrieving #{c.id}..."
          coupon = Stripe::Coupon.retrieve(c.id)
        rescue Stripe::InvalidRequestError => e
          unless e.message.include?('No such coupon')
            @logger.debug e.inspect
            rase e
          end
        end

        if coupon.nil?
          @logger.info "Doesn't exist.  Creating #{c.id}..."
          begin
            Stripe::Coupon.create(
              id: c.id,
              name: c.name,
              currency: c.currency,
              duration: c.duration,
              duration_in_months: c.duration_in_months,
              amount_off: c.amount_off,
              percent_off: c.percent_off,
              max_redemptions: c.max_redemptions,
              redeem_by: c.redeem_by
            )
          rescue StandardError => e
            @logger.info e.inspect
          end
        else
          @logger.info 'Already exists. Skipping.'
        end
      end
    end

    def update_customers(api_key:, customers:, read_only: false)
      @logger.info "UPDATING CUSTOMERS IN #{api_key}"
      Stripe.api_key = api_key

      customers.each do |c|
        next unless c.account_balance != 0

        @logger.info "Migrating account balance for #{c.id} of #{c.account_balance}"

        next if read_only

        cu = Stripe::Customer.retrieve(c.id)
        cu.account_balance = c.account_balance
        cu.save
      end
      true
    end

    def update_products(api_key:, products:)
      @logger.info "UPDATING PRODUCTS IN #{api_key}"
      Stripe.api_key = api_key

      products.each do |p|
        begin
          @logger.info "Retrieving #{p.id}..."
          product = Stripe::Product.retrieve(p.id)
        rescue Stripe::InvalidRequestError => e
          unless e.message.include?('No such product')
            @logger.debug e.inspect
            rase e
          end
        end

        if product.nil?
          @logger.info "Doesn't exist.  Creating #{p.id}..."
          begin
            Stripe::Product.create(
              id: p.id,
              name: p.name,
              type: p.type,
              statement_descriptor: p.statement_descriptor,
              unit_label: p.unit_label
            )
          rescue StandardError => e
            @logger.info e.inspect
          end
        else
          @logger.info 'Already exists. Skipping.'
        end
      end
    end

    def update_plans(api_key:, plans:)
      @logger.info "UPDATING PLANS IN #{api_key}"
      Stripe.api_key = api_key

      plans.each do |p|
        begin
          @logger.info "Retrieving #{p.id}..."
          plan = Stripe::Plan.retrieve(p.id)
        rescue Stripe::InvalidRequestError => e
          unless e.message.include?('No such plan')
            @logger.debug e.inspect
            raise e
          end
        end

        if plan.nil?
          @logger.info "Doesn't exist.  Creating #{p.id}..."
          begin
            Stripe::Plan.create(
              id: p.id,
              product: p.product,
              nickname: p.nickname,
              amount: p.amount,
              currency: p.currency,
              interval: p.interval,
              trial_period_days: p.trial_period_days
            )
          rescue StandardError => e
            @logger.debug e.inspect
            raise e
          end
        else
          @logger.info 'Already exists. Skipping.'
        end
      end
    end

    private

    def sub_migrator
      StripeMigrant::Subscription.new(
        source_key: @source_key,
        target_key: @target_key,
        logger: @logger
      )
    end
  end
end
