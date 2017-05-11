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

          if result = @order.update_attributes(email: @params[:email])
            @order.associate_user!(@user, @order.email.blank?) unless guest_checkout?

            set_addresses_by_ids

            # OVERRIDE to use Spree Address Book settings to prevent overwriting of
            # any stored addresses since update attributes
            set_addresses_by_attributes

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
            @order.bill_address_attributes = bill_address_params
          end

          if @params[:ship_address_id].blank?
            @order.ship_address_attributes = ship_address_params
          end
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

        def order_params
          @params.permit(:email, :ship_address_id, :bill_address_id)
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
