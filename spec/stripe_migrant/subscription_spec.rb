# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StripeMigrant::Subscription do
  let(:klass) do
    described_class.new(source_key: api_key, target_key: api_key, logger: logger)
  end
  let(:logger) do
    l = Logger.new(STDOUT)
    l.level = Logger::FATAL
    l
  end
  let(:api_key) { 'fake_key' }
  subject { klass }

  it { is_expected.to be }

  describe '#get_all' do
    subject { klass.get_all }
    let(:subscriptions) { [double(:subscription)] }
    let(:sub_list) { double(:sub_list, data: subscriptions) }

    before(:each) { allow(Stripe::Subscription).to receive(:all).and_return(sub_list) }

    it { is_expected.to eq(subscriptions) }
  end

  describe '#confirm_all' do
    subject { klass.confirm_all(subscriptions: subscriptions) }
    let(:sub) do
      double(:sub, id: 'sub_1', customer: 'cus_1', metadata: metadata, status: 'a', plan: plan)
    end
    let(:plan) { double(:plan, id: 'plan_1') }
    let(:metadata) { { prior_sub_id: 'sub_1' } }
    let(:subscriptions) { [sub] }
    let(:sub_list) { double(:sub_list, data: subscriptions) }

    before(:each) { allow(Stripe::Subscription).to receive(:list).and_return(sub_list) }

    it { is_expected.to eq(subscriptions) }
  end

  describe '#create_all' do
    subject { klass.create_all(subscriptions: subscriptions) }
    let(:subscription) do
      double(
        :subscription,
        id: 'sub_1',
        customer: 'cus_1',
        status: 'active',
        billing_cycle_anchor: 500_000,
        current_period_end: 900_000,
        cancel_at_period_end: true,
        discount: nil,
        trial_end: 10_000,
        prorate: false,
        items: [double(:item, plan: double(:plan, id: 'plan_1'))]
      )
    end
    let(:subscriptions) { [subscription] }
    let(:customer) { double(:customer, id: 'cus_1', subscriptions: c_subs) }
    let(:c_subs) { double(:c_subs, data: []) }

    before(:each) do
      allow(Stripe::Customer).to receive(:retrieve).and_return(customer)
      allow(Stripe::Subscription).to receive(:create).and_return(subscription)
    end

    it 'creates a subscription' do
      expect(Stripe::Subscription).to receive(:create).with(any_args)
      subject
    end
  end
end
