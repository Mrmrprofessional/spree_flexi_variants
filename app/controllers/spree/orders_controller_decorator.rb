module Spree
  OrdersController.class_eval do

    include ProductCustomizations
    include AdHocUtils

    before_action :set_option_params_values, only: [:populate]
    before_action :check_variant_exclusions, only: [:populate]

    # Adds a new item to the order (creating a new order if none already exists)
    def populate
      order    = current_order(create_order_if_necessary: true)
      variant  = Spree::Variant.find(params[:variant_id])
      quantity = params[:quantity].to_i
      options  = params[:options] || {}

      # 2,147,483,647 is crazy. See issue #2695.
      if quantity.between?(1, 2_147_483_647)
        begin
          order.contents.add(variant, quantity, options)
          order.create_tax_charge!
          order.update_with_updater!
        rescue ActiveRecord::RecordInvalid => e
          error = e.record.errors.full_messages.join(', ')
        end
      else
        error = Spree.t(:please_enter_reasonable_quantity)
      end

      if error
        flash[:error] = error
        redirect_back_or_default(spree.root_path)
      else
        respond_with(order) do |format|
          format.html { redirect_to(cart_path(variant_id: variant.id)) }
        end
      end
    end

    private

    def set_option_params_values
      params[:options] ||= {}
      params[:options][:ad_hoc_option_values] = ad_hoc_option_value_ids
      params[:options][:product_customizations] = product_customizations
      params[:options][:customization_price] = params[:customization_price] if params[:customization_price]
    end

    def check_variant_exclusions
      ahv = AdHocVariantExclusion.where(product: params[:variant_id])
      ahv.each do |v|
         @values = []
         v.excluded_ad_hoc_option_values.each do |r|
            @values.push(r.ad_hoc_option_value.id.to_s)
         end
         if (@values - ad_hoc_option_value_ids).empty?
           flash[:danger] = "The chosen options are incompatible with your current configuration."
           redirect_back_or_default(spree.root_path)
         end
      end
    end
  end
end
