module SpreePromotionActionCreateLineItems
  # 商品ページ・カートのボタンを隠すだけでは、リクエストを直接送れば操作できてしまうため、
  # サーバー側でも拒否する。Spree.cart_add_item_service でガードすると、同じサービスを呼ぶ
  # プロモーションの追加処理まで止まるので、お客様の操作の入り口であるコントローラーで止める。
  module LineItemsControllerDecorator
    def self.prepended(base)
      # campaign_line_item? の判定は LineItemsHelper に一元化しているため、
      # コントローラーからも同じ実装を共有する。
      base.include SpreePromotionActionCreateLineItems::LineItemsHelper
      base.before_action :prevent_campaign_variant_add, only: [ :create ]
      base.before_action :prevent_campaign_line_item_modification, only: [ :update, :destroy ]
    end

    private

    def prevent_campaign_variant_add
      return unless @variant&.campaign_variant?

      handle_campaign_line_item_error
    end

    def prevent_campaign_line_item_modification
      return unless campaign_line_item?(@line_item)

      handle_campaign_line_item_error
    end

    def handle_campaign_line_item_error
      flash_message = Spree.t('campaign_line_item.cannot_modify')
      if request.format.turbo_stream?
        return campaign_line_item_error_stream(flash_message) unless action_name == 'create'

        # create はカートに何も入れていないので、エラーメッセージの更新だけを返す
        flash.now[:error] = flash_message
        return render(template: 'spree/line_items/create', formats: [ :turbo_stream ])
      end

      flash[:error] = flash_message
      redirect_to spree.cart_path(order_token: order_token)
    end

    # upstream の spree/line_items/{update,destroy}.turbo_stream.erb は flash[:error] の
    # 有無で出力が分岐する（error あり→flash更新のみ／error なし→カート再描画）。
    # その性質を利用し、同じテンプレートを flash 設定の前後で2回レンダリングして
    #   1. 変更を拒否したことによる「カートの再描画」（flash 未設定で生成）
    #   2. エラーメッセージの「flash 更新」（flash 設定後に生成）
    # の両方を1レスポンスにまとめて返す。
    def campaign_line_item_error_stream(flash_message)
      @order ||= current_order
      load_line_items
      template = "spree/line_items/#{action_name}"

      # flash 未設定 → カート一覧の再描画ストリーム
      cart_refresh_stream = render_to_string(template: template, formats: [ :turbo_stream ])

      # flash 設定後 → エラーメッセージ更新ストリーム
      flash.now[:error] = flash_message
      flash_message_stream = render_to_string(template: template, formats: [ :turbo_stream ])

      render turbo_stream: [ flash_message_stream, cart_refresh_stream ]
    end
  end
end

if Spree::LineItemsController.included_modules.exclude?(SpreePromotionActionCreateLineItems::LineItemsControllerDecorator)
  Spree::LineItemsController.prepend(SpreePromotionActionCreateLineItems::LineItemsControllerDecorator)
end
