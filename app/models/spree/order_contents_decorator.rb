module Spree
  OrderContents.class_eval do

    private
    #this whole thing needs a refactor!

    def add_to_line_item(variant, quantity, options = {})
      pp options[:ad_hoc_option_values]
      line_item = grab_line_item_by_variant(variant, false, options)
      if line_item
        puts "duplicate item"
        line_item.quantity += quantity.to_i
        line_item.currency = currency unless currency.nil?
      else
        puts "new item"
        options_params = options.is_a?(ActionController::Parameters) ? options : ActionController::Parameters.new(options.to_h)
        puts "options_params:"

        pp options_params
        opts = options_params.
          permit(PermittedAttributes.line_item_attributes).to_h.
          merge(currency: order.currency)

        line_item = order.line_items.new(quantity: quantity, variant: variant, options: opts)

        product_customizations_values = options[:product_customizations] || []
        line_item.product_customizations = product_customizations_values
        product_customizations_values.each { |product_customization| product_customization.line_item = line_item }
        product_customizations_values.map(&:save) # it is now safe to save the customizations we built

        # find, and add the configurations, if any.  these have not been fetched from the db yet.              line_items.first.variant_id
        # we postponed it (performance reasons) until we actually know we needed them
        puts "options[:ad_hoc_option_values]:"
        pp options[:ad_hoc_option_values]
        ad_hoc_option_value_ids = ( !!options[:ad_hoc_option_values] ? options[:ad_hoc_option_values] : [] )
        product_option_values = ad_hoc_option_value_ids.map do |cid|
          AdHocOptionValue.find(cid) if cid.present?
        end.compact
        puts "product option values:"
        pp product_option_values
        line_item.ad_hoc_option_values = product_option_values

        offset_price = product_option_values.map(&:price_modifier).compact.sum + product_customizations_values.map {|product_customization| product_customization.price(variant)}.compact.sum
        puts "offset price:"
        pp  offset_price
        if currency
          line_item.currency = currency unless currency.nil?
          line_item.price    = variant.price_in(currency).amount + offset_price
        else
          line_item.price    = variant.price + offset_price
        end
        puts "price:"
        pp line_item.price
      end
      line_item.target_shipment = options[:shipment] if options.has_key? :shipment
      line_item.save!
      line_item
    end
  end
end
