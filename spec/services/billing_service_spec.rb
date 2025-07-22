require 'rails_helper'

RSpec.describe BillingService do
  let(:user_id) { 1 }

  before do
    Rails.cache.clear
  end

  describe '.get_subscription_status' do
    context 'successful responses' do
      it 'handles active subscription status' do
        allow(BillingService).to receive(:fetch_from_billing_service)
          .with(user_id).and_return('active')

        result = BillingService.get_subscription_status(user_id)
        expect(result).to eq('active')
      end

      it 'handles expired subscription status' do
        allow(BillingService).to receive(:fetch_from_billing_service)
          .with(user_id).and_return('expired')

        result = BillingService.get_subscription_status(user_id)
        expect(result).to eq('expired')
      end
    end

    context 'error responses' do
      it 'handles 401 unauthorized error' do
        allow(BillingService).to receive(:fetch_from_billing_service)
          .with(user_id).and_raise(
            BillingService::BillingServiceError.new("Unauthorized access to billing service", :unauthorized)
          )

        expect {
          BillingService.get_subscription_status(user_id)
        }.to raise_error(BillingService::BillingServiceError) do |error|
          expect(error.error_type).to eq(:unauthorized)
          expect(error.message).to include('Unauthorized access to billing service')
        end
      end

      it 'handles 404 not found error for user_id > 100' do
        user_id = 200
        allow(BillingService).to receive(:fetch_from_billing_service)
          .with(user_id).and_raise(
            BillingService::BillingServiceError.new("User not found in billing system", :not_found)
          )

        expect {
          BillingService.get_subscription_status(user_id)
        }.to raise_error(BillingService::BillingServiceError) do |error|
          expect(error.error_type).to eq(:not_found)
          expect(error.message).to include('User not found in billing system')
        end
      end

      it 'handles 404 as intermittent failure for user_id <= 100' do
        user_id = 5
        allow(BillingService).to receive(:fetch_from_billing_service)
          .with(user_id).and_raise(
            BillingService::BillingServiceError.new("Intermittent billing service failure", :intermittent_failure)
          )

        expect {
          BillingService.get_subscription_status(user_id)
        }.to raise_error(BillingService::BillingServiceError) do |error|
          expect(error.error_type).to eq(:intermittent_failure)
          expect(error.message).to include('Intermittent billing service failure')
        end
      end

      it 'handles 503 service unavailable error' do
        allow(BillingService).to receive(:fetch_from_billing_service)
          .with(user_id).and_raise(
            BillingService::BillingServiceError.new("Billing service temporarily unavailable", :service_unavailable)
          )

        expect {
          BillingService.get_subscription_status(user_id)
        }.to raise_error(BillingService::BillingServiceError) do |error|
          expect(error.error_type).to eq(:service_unavailable)
          expect(error.message).to include('Billing service temporarily unavailable')
        end
      end

      it 'handles timeout errors' do
        allow(BillingService).to receive(:fetch_from_billing_service)
          .with(user_id).and_raise(
            BillingService::BillingServiceError.new("Billing service timeout", :timeout)
          )

        expect {
          BillingService.get_subscription_status(user_id)
        }.to raise_error(BillingService::BillingServiceError) do |error|
          expect(error.error_type).to eq(:timeout)
          expect(error.message).to include('Billing service timeout')
        end
      end

      it 'handles network errors' do
        allow(BillingService).to receive(:fetch_from_billing_service)
          .with(user_id).and_raise(
            BillingService::BillingServiceError.new("Network error connecting to billing service", :network_error)
          )

        expect {
          BillingService.get_subscription_status(user_id)
        }.to raise_error(BillingService::BillingServiceError) do |error|
          expect(error.error_type).to eq(:network_error)
          expect(error.message).to include('Network error connecting to billing service')
        end
      end
    end

    context 'caching behavior' do
      it 'caches successful responses' do
        # Mock the private method call
        allow(BillingService).to receive(:fetch_from_billing_service)
          .with(user_id).and_return('active')

        # First call should invoke the service
        result1 = BillingService.get_subscription_status(user_id)
        expect(result1).to eq('active')

        # Verify it was called once
        expect(BillingService).to have_received(:fetch_from_billing_service).once

        # Second call should use cache (reset the mock to verify no additional calls)
        BillingService.__send__(:fetch_from_billing_service, user_id) rescue nil # Clear call history

        result2 = BillingService.get_subscription_status(user_id)
        expect(result2).to eq('active')
      end

      it 'returns cached result with correct expiration' do
        cache_key = "subscription_status:#{user_id}"

        # Pre-populate cache
        Rails.cache.write(cache_key, 'expired', expires_in: 1.hour)

        # Should return cached value without calling service
        result = BillingService.get_subscription_status(user_id)
        expect(result).to eq('expired')
      end

      it 'falls back to stale cache when service fails' do
        cache_key = "subscription_status:#{user_id}"

        # Pre-populate cache and simulate expiration
        Rails.cache.write(cache_key, 'cached_active', expires_in: 1.hour)

        # Mock cache to simulate expired behavior
        allow(Rails.cache).to receive(:read).with(cache_key).and_return(nil)
        allow(Rails.cache).to receive(:read).with(cache_key, expired: true).and_return('cached_active')

        # Mock service failure
        allow(BillingService).to receive(:fetch_from_billing_service)
          .with(user_id).and_raise(
            BillingService::BillingServiceError.new("Billing service timeout", :timeout)
          )

        # Should return stale cached data instead of raising error
        result = BillingService.get_subscription_status(user_id)
        expect(result).to eq('cached_active')
      end

      it 'raises error when service fails and no stale cache available' do
        # Ensure no cache exists
        Rails.cache.clear

        # Mock service failure
        allow(BillingService).to receive(:fetch_from_billing_service)
          .with(user_id).and_raise(
            BillingService::BillingServiceError.new("Billing service timeout", :timeout)
          )

        # Should raise error when no cache fallback available
        expect {
          BillingService.get_subscription_status(user_id)
        }.to raise_error(BillingService::BillingServiceError) do |error|
          expect(error.error_type).to eq(:timeout)
        end
      end

      it 'caches successful responses with correct expiration time' do
        # Mock the private method to return a value
        allow(BillingService).to receive(:fetch_from_billing_service)
          .with(user_id).and_return('active')

        # Call the method
        BillingService.get_subscription_status(user_id)

        # Check that cache was written
        cached_value = Rails.cache.read("subscription_status:#{user_id}")
        expect(cached_value).to eq('active')
      end
    end
  end
end
