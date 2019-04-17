# frozen_string_literal: true

require 'logger'

module StripeMigrant
  class Subscription
    def initialize(source_key:, target_key:, logger: Logger.new)
      @logger = logger
      @source_key = source_key
      @target_key = target_key
      Stripe.set_app_info(
        'StripeMigrant',
        version: StripeMigrant::VERSION,
        url: 'https://www.github.com/codetree/stripe_migrant'
      )
    end

    def confirm_all(subscriptions:, use_target_key: true)
      @logger.info 'Building list of subscriptions confirmed to exist'
      set_api_key(use_target_key: use_target_key)
      confirmed_subs = []

      subscriptions.each do |sub|
        sub_list = Stripe::Subscription.list(
          customer: sub.customer,
          status: sub.status,
          plan: sub.plan.id
        )
        new_sub = sub_list.data.first
        if !new_sub.nil? && new_sub.metadata[:prior_sub_id] == sub.id
          confirmed_subs << sub
        else
          @logger.info "sub not found: #{sub.id}"
        end
      rescue StandardError => e
        if e.message.include? 'No such customer'
          @logger.info "customer not found: #{sub.customer}"
        else
          @logger.fatal e.inspect
          @logger.fatal sub
          raise e
        end
      end
      confirmed_subs
    end

    def cancel_all(subscriptions:, use_source_key: true)
      @logger.info 'Deleting Origin Subscriptions'
      set_api_key(use_target_key: !use_source_key)
      subscriptions.each do |sub|
        Stripe::Subscription.retrieve(sub.id).delete
      end
    end

    def get_all(use_source_key: true)
      set_api_key(use_target_key: !use_source_key)
      limit = 100
      su = []
      subs = []

      while subs.empty? || su.count == limit # ensure first run and when per-page limit reached
        @logger.info "getting page #{(subs.count / limit) + 1} of subs"
        su = Stripe::Subscription.all({ limit: limit, starting_after: su.last }.compact).data
        subs += su
      end
      subs
    end

    def create_all(subscriptions:, use_target_key: true)
      @logger.info 'CREATING SUBSCRIPTIONS'
      new_subs = []

      subscriptions.each do |sub|
        @logger.info "Adding subscription #{sub.id}"

        customer = retrieve_customer(sub.customer, @target_key)

        next if customer.nil?

        if customer.subscriptions.data.count.positive?
          @logger.info "Customer #{customer.id} already has a sub"
          next
        end

        # build base hash;
        # TODO: only supports single item subscriptions
        hsh = {
          customer: sub.customer,
          billing_cycle_anchor: nil,
          cancel_at_period_end: sub.cancel_at_period_end,
          coupon: nil,
          trial_end: nil,
          prorate: false,
          items: [{
            plan: sub.items.first.plan.id,
            quantity: 1
          }],
          metadata: {
            prior_sub_id: sub.id,
            has_received_trial_will_end_email: sub.trial_end &&
                                               (sub.trial_end - Time.now.to_i) < (60 * 60 * 24 * 3)
          }
        }

        # set coupon if exists
        hsh[:coupon] = sub.discount.coupon.id unless sub.discount.nil?

        # keep same billing cycle anchor if active subscription
        hsh[:billing_cycle_anchor] = sub.current_period_end if sub.status == 'active'

        # attempt to charge subscription immediately if past_due
        hsh[:trial_end] = (Time.now + 30).to_i if sub.status == 'past_due'

        # set trial_end if still in trialing period
        hsh[:trial_end] = sub.trial_end if sub.status == 'trialing'

        # update Target customer with sub
        begin
          new_sub = Stripe::Subscription.create(hsh)
          @logger.info "Added subscription #{new_sub.id}"
          new_subs << new_sub
        rescue StandardError => e
          @logger.fatal e.inspect
          @logger.fatal sub
          @logger.fatal hsh
          raise e
        end
        @logger.info 'Subscription Updates Completed'
        new_subs
      end
    end

    private

    def retrieve_stripe_customer(id, api_key)
      Stripe.api_key = api_key
      Stripe::Customer.retrieve(id)

    rescue StandardError => e
      @logger.info "Missing Customer #{sub.customer}"
      @logger.fatal e.inspect
    end

    def set_api_key(use_target_key:)
      Stripe.api_key = use_target_key ? @target_key : @source_key
    end
  end
end
