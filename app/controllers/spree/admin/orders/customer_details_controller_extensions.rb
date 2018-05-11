module Spree
  module Admin
    module Orders
      module CustomerDetailsControllerExtensions

        def edit
          super
          load_addresses
        end

        def update
          prepare_params
          load_addresses

          if @order.update_attributes(email: @params[:email])
            @order.associate_user!(@user, @order.email.blank?) unless guest_checkout?

            # Use Spree Address Book setters instead of direct update_attributes to prevent
            # overwriting of any stored addresses
            set_addresses_by_ids
            set_addresses_by_attributes

            # required when returning for a completed order that needs an address update
            # to ensure shipment has correct shipping address on unshipped orders
            update_unshipped_shipments

            @order.next unless @order.complete?

            @order.refresh_shipment_rates(Spree::ShippingMethod::DISPLAY_ON_FRONT_AND_BACK_END)

            if @order.errors.empty?
              flash[:success] = Spree.t('customer_details_updated')
              redirect_to edit_admin_order_url(@order)
            else
              render action: :edit
            end
          else
            render action: :edit
          end
        end

        private

        def update_unshipped_shipments
          @order.shipments.with_state([:ready, :pending]).each do |s|
            s.address = @order.ship_address
            s.save
          end
        end

        def load_addresses
          @addresses = @order.user.nil? ? [] : @order.user.addresses
        end

        def set_addresses_by_ids
          @order.bill_address_id = @params[:bill_address_id] unless @params[:bill_address_id].blank?
          @order.ship_address_id = @params[:ship_address_id] unless @params[:ship_address_id].blank?

          @order.save
        end

        def set_addresses_by_attributes
          if @params[:bill_address_id].blank?
            if @params[:ship_address_id].blank?
              @order.use_billing = @params[:use_billing]
            end
            @order.bill_address_attributes = bill_address_params.merge(user_id: @order.user_id)
          end

          if @params[:ship_address_id].blank?
            @order.ship_address_attributes = ship_address_params.merge(user_id: @order.user_id)
          end
          @order.save
        end

        def bill_address_params
          @params.permit(
            bill_address_attributes: permitted_address_attributes,
          )[:bill_address_attributes]
        end

        def ship_address_params
          if shipping_same_as_billing?
            bill_address_params
          else
            @params.permit(
              ship_address_attributes: permitted_address_attributes,
            )[:ship_address_attributes]
          end
        end

        def prepare_params
          @params = params.require(:order)
          unless @params[:ship_address_id].blank?
            @params.delete(:ship_address_attributes)
            @params.delete(:use_billing)
          end

          unless @params[:bill_address_id].blank?
            @params.delete(:bill_address_attributes)
            if shipping_same_as_billing? && @params[:ship_address_id].blank?
              @params[:ship_address_id] = @params[:bill_address_id]
            end
          end
        end

        def shipping_same_as_billing?
          @params[:use_billing] && @params[:use_billing].in?([true, 'true', '1'])
        end
      end
    end
  end
end
