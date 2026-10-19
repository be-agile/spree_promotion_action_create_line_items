module SpreePromotionActionCreateLineItems
  module VariantDecorator
    # プロモーションがカートに追加する商品（キャンペーン商品）かどうか。
    # プロモーションの期間・状態は見ず、アクションに設定が残っていればキャンペーン商品とする。
    # 他の engine が独自のアクションの商品を加えられるよう、prepend して super で拡張する。
    def campaign_variant?
      Spree::PromotionActionLineItem.exists?(variant_id: id)
    end
  end
end

Spree::Variant.prepend(SpreePromotionActionCreateLineItems::VariantDecorator)
