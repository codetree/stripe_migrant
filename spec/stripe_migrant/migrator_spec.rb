require 'spec_helper'

RSpec.describe StripeMigrant::Migrator do
  let(:migrator) { described_class.new(log_level: Logger::FATAL) }
  let(:api_key) { 'fake_key' }
  subject { migrator }

  it { is_expected.to be }

  describe '#get_plans' do
    subject { migrator.get_plans(api_key) }
    let(:plans) { [double(:plan)] }

    before(:each) { allow(Stripe::Plan).to receive(:all).and_return(plans) }

    it { is_expected.to eq(plans) }
  end

  describe '#get_products' do
    subject { migrator.get_products(api_key) }
    let(:products) { [double(:product)] }

    before(:each) { allow(Stripe::Product).to receive(:all).and_return(products) }

    it { is_expected.to eq(products) }
  end

  describe '#update_plans' do
    subject { migrator.update_plans(plans, api_key) }
    let(:plan) do
      double(
        :plan,
        id: '1',
        product: 'plan_1',
        nickname: 'nickname',
        amount:   100,
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
        id:                 plan.id,
        product:            plan.product,
        nickname:           plan.nickname,
        amount:             plan.amount,
        currency:           plan.currency,
        interval:           plan.interval,
        trial_period_days:  plan.trial_period_days
      )
      subject
    end
  end

  describe '#update_products' do
    subject { migrator.update_products(products, api_key) }
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
        id:                   product.id,
        name:                 product.name,
        type:                 product.type,
        statement_descriptor: product.statement_descriptor,
        unit_label:           product.unit_label
      )
      subject
    end
  end
end
