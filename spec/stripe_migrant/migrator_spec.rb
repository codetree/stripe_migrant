# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StripeMigrant::Migrator do
  let(:migrator) do
    described_class.new(source_key: api_key, target_key: api_key, log_level: Logger::FATAL)
  end
  let(:api_key) { 'fake_key' }
  subject { migrator }

  it { is_expected.to be }

  describe '#cancel_confirmed_subscriptions' do
    subject { migrator.cancel_confirmed_subscriptions }
    let(:subscriptions) { [double(:subscription)] }
    let(:new_subs) { [double(:new_sub)] }
    let(:sub_instance) do
      double(:sub_instance, get_all: subscriptions, confirm_all: new_subs, cancel_all: true)
    end

    before(:each) do
      allow(StripeMigrant::Subscription).to receive(:new).and_return(sub_instance)
    end

    it 'retrieves all existing subscriptions' do
      expect(sub_instance).to receive(:get_all).with(no_args)
      subject
    end

    it 'creates a list of confirmed existing subscriptions in destination' do
      expect(sub_instance).to receive(:confirm_all).with(subscriptions: subscriptions)
      subject
    end
  end

  describe '#get_coupons' do
    subject { migrator.get_coupons(api_key: api_key) }
    let(:coupons) { [double(:coupons)] }

    before(:each) { allow(Stripe::Coupon).to receive(:all).and_return(coupons) }

    it { is_expected.to eq(coupons) }
  end

  describe '#get_customers' do
    subject { migrator.get_customers(api_key: api_key) }
    let(:customers) { [double(:customer)] }
    let(:customers_list) { double(:customers_list, data: customers) }

    before(:each) { allow(Stripe::Customer).to receive(:all).and_return(customers_list) }

    it { is_expected.to eq(customers) }
  end

  describe '#get_plans' do
    subject { migrator.get_plans(api_key: api_key) }
    let(:plans) { [double(:plan)] }

    before(:each) { allow(Stripe::Plan).to receive(:all).and_return(plans) }

    it { is_expected.to eq(plans) }
  end

  describe '#get_products' do
    subject { migrator.get_products(api_key: api_key) }
    let(:products) { [double(:product)] }

    before(:each) { allow(Stripe::Product).to receive(:all).and_return(products) }

    it { is_expected.to eq(products) }
  end

  describe '#migrate_subscriptions' do
    subject { migrator.migrate_subscriptions }
    let(:subscriptions) { [double(:subscription)] }
    let(:new_subs) { [double(:new_sub)] }
    let(:sub_instance) { double(:sub_instance, get_all: subscriptions, create_all: new_subs) }

    before(:each) do
      allow(StripeMigrant::Subscription).to receive(:new).and_return(sub_instance)
    end

    it 'retrieves all existing subscriptions' do
      expect(sub_instance).to receive(:get_all).with(no_args)
      subject
    end

    it 'creates all new subscriptions from existing subscriptions' do
      expect(sub_instance).to receive(:create_all).with(subscriptions: subscriptions)
      subject
    end
  end

  describe '#update_customers' do
    subject { migrator.update_customers(api_key: api_key, customers: customers) }
    let(:customers) { [customer] }
    let(:customer) do
      double(
        :customer,
        id: 'c_1',
        account_balance: 0,
        save: true
      )
    end

    it { is_expected.to eq(true) }
  end

  describe '#update_coupons' do
    subject { migrator.update_coupons(api_key: api_key, coupons: coupons) }
    let(:coupon) do
      double(
        :coupon,
        id: '1',
        name: 'name',
        currency: 'usd',
        duration: 'forever',
        duration_in_months: 3,
        amount_off: nil,
        percent_off: 25.5,
        max_redemptions: 1,
        redeem_by: nil
      )
    end
    let(:coupons) { [coupon] }

    before(:each) do
      allow(Stripe::Coupon).to receive(:retrieve).and_return(nil)
    end

    it 'expect Stripe::Coupon to receive correct attributes' do
      expect(Stripe::Coupon).to receive(:create).with(
        id: coupon.id,
        name: coupon.name,
        currency: coupon.currency,
        duration: coupon.duration,
        duration_in_months: coupon.duration_in_months,
        amount_off: coupon.amount_off,
        percent_off: coupon.percent_off,
        max_redemptions: coupon.max_redemptions,
        redeem_by: coupon.redeem_by
      )
      subject
    end
  end

  describe '#update_plans' do
    subject { migrator.update_plans(api_key: api_key, plans: plans) }
    let(:plan) do
      double(
        :plan,
        id: '1',
        product: 'plan_1',
        nickname: 'nickname',
        amount: 100,
        currency: 'USD',
        interval: 'month',
        trial_period_days: 14
      )
    end
    let(:plans) { [plan] }

    before(:each) do
      allow(Stripe::Plan).to receive(:retrieve).and_return(nil)
    end

    it 'expect Stripe::Plan to receive correct attributes' do
      expect(Stripe::Plan).to receive(:create).with(
        id: plan.id,
        product: plan.product,
        nickname: plan.nickname,
        amount: plan.amount,
        currency: plan.currency,
        interval: plan.interval,
        trial_period_days: plan.trial_period_days
      )
      subject
    end
  end

  describe '#update_products' do
    subject { migrator.update_products(api_key: api_key, products: products) }
    let(:product) do
      double(
        :product,
        id: '1',
        name: 'name',
        type: 'service',
        statement_descriptor: 'descriptor',
        unit_label: 'account'
      )
    end
    let(:products) { [product] }

    before(:each) do
      allow(Stripe::Product).to receive(:retrieve).and_return(nil)
    end

    it 'expect Stripe::Product to receive correct attributes' do
      expect(Stripe::Product).to receive(:create).with(
        id: product.id,
        name: product.name,
        type: product.type,
        statement_descriptor: product.statement_descriptor,
        unit_label: product.unit_label
      )
      subject
    end
  end
end
