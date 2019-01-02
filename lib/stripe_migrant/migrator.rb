require 'logger'

module StripeMigrant
  class Migrator

    def initialize(output_file: STDOUT, log_level: Logger::DEBUG)
      @logger = Logger.new(output_file)
      @logger.level = log_level
      Stripe.set_app_info(
        'StripeMigrant',
        version: StripeMigrant::VERSION,
        url: 'https://www.github.com/codetree/stripe_migrant'
      )
    end

    def get_products(api_key)
      Stripe.api_key = api_key
      Stripe::Product.all({limit: 100})
    end

    def get_plans(api_key)
      Stripe.api_key = api_key
      Stripe::Plan.all({limit: 100})
    end

    def update_products(products, api_key)
      @logger.info "UPDATING PRODUCTS IN #{api_key}"
      Stripe.api_key = api_key

      products.each do |p|
        begin
          @logger.info "Retrieving #{p.id}..."
          product = Stripe::Product.retrieve(p.id)
        rescue Stripe::InvalidRequestError => e
          unless e.message.include?("No such product")
            @logger.debug e.inspect
            rase e
          end
        end

        if product.nil?
          @logger.info "Doesn't exist.  Creating #{p.id}..."
          begin
            Stripe::Product.create(
              id:     p.id,
              name:   p.name,
              type:   p.type,
              statement_descriptor: p.statement_descriptor,
              unit_label: p.unit_label
            )
          rescue Exception => e
            @logger.info e.inspect
          end
        else
          @logger.info "Already exists. Skipping."
        end
      end
    end

    def update_plans(plans, api_key)
      @logger.info "UPDATING PLANS IN #{api_key}"
      Stripe.api_key = api_key

      plans.each do |p|
        begin
          @logger.info "Retrieving #{p.id}..."
          plan = Stripe::Plan.retrieve(p.id)
        rescue Stripe::InvalidRequestError => e
          unless e.message.include?("No such plan")
            @logger.debug e.inspect
            raise e
          end
        end

        if plan.nil?
          @logger.info "Doesn't exist.  Creating #{p.id}..."
          begin
            Stripe::Plan.create(
              id:                 p.id,
              product:            p.product,
              nickname:           p.nickname,
              amount:             p.amount,
              currency:           p.currency,
              interval:           p.interval,
              trial_period_days:  p.trial_period_days
            )
          rescue Exception => e
            @logger.debug e.inspect
            raise e
          end
        else
          @logger.info "Already exists. Skipping."
        end
      end
    end
  end
end
