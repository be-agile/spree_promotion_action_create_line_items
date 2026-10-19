module SpreePromotionActionCreateLineItems
  module CartControllerDecorator
    def self.prepended(base)
      base.before_action :prevent_campaign_variant_add,          only: [ :add_item ]
      base.before_action :prevent_campaign_line_item_api_modify, only: [ :remove_line_item, :set_quantity ]
    end

    private

    def prevent_campaign_variant_add
      variant = Spree::Variant.find_by(id: params[:variant_id])
      return unless variant&.campaign_variant?

      render json: { error: Spree.t('campaign_line_item.cannot_modify') }, status: 422
    end

    def prevent_campaign_line_item_api_modify
      li = spree_current_order.line_items.find_by(id: params[:line_item_id])
      return unless li&.variant&.campaign_variant?

      render json: { error: Spree.t('campaign_line_item.cannot_modify') }, status: 422
    end
  end
end

if Spree::Api::V2::Storefront::CartController.included_modules.exclude?(SpreePromotionActionCreateLineItems::CartControllerDecorator)
  Spree::Api::V2::Storefront::CartController.prepend(SpreePromotionActionCreateLineItems::CartControllerDecorator)
end
