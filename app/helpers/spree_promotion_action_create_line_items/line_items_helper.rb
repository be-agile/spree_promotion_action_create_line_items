module SpreePromotionActionCreateLineItems
  module LineItemsHelper
    def campaign_line_item?(line_item)
      !!line_item&.variant&.campaign_variant?
    end
  end
end
