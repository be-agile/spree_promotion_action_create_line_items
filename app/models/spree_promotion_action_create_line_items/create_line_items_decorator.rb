module SpreePromotionActionCreateLineItems
  # PromotionHandler::Cart はカートの明細を追加・変更・削除するたびに、その明細を対象に
  # Promotion#eligible? を評価する。注文に対するルール（対象商品など）しか持たないプロモーションは
  # 明細に対しては常に適用可と判定されるので、条件を外れても revert が呼ばれず、キャンペーン商品が残る。
  # お客様はキャンペーン商品を自分で削除できないため、perform で注文に対する条件を確かめ、外れていれば外す。
  module CreateLineItemsDecorator
    def perform(options = {})
      return super if eligible?(options[:order])

      revert(options)
      false
    end
  end
end

Spree::Promotion::Actions::CreateLineItems.prepend(SpreePromotionActionCreateLineItems::CreateLineItemsDecorator)
