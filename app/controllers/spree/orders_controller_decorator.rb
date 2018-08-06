module Spree
  OrdersController.class_eval do

    include ProductCustomizations
    include AdHocUtils

    before_action :set_option_params_values, only: [:populate]
    before_action :check_variant_exclusions, only: [:populate]

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
