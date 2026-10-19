require 'spec_helper'

RSpec.describe 'Storefront LineItems campaign guard', type: :request do
  let!(:store) { create(:store) }
  let(:order) { create(:order, store: store, state: 'cart', completed_at: nil) }

  let(:campaign_variant) { create(:product).master }
  let(:normal_variant) { create(:product).master }
  let(:error_message) { Spree.t('campaign_line_item.cannot_modify') }
  let(:promotion) { create(:promotion, kind: :automatic, code: nil) }

  before do
    host! 'test.localhost'
    action = create(:promotion_action_create_line_items, promotion: promotion)
    action.promotion_action_line_items.create!(variant: campaign_variant, quantity: 1)
  end

  describe 'POST create' do
    subject(:create_line_item) do
      post '/line_items', params: { order_token: order.token, variant_id: variant.id, quantity: 1 }, headers: headers
    end

    let(:headers) { {} }

    context 'キャンペーン商品の場合' do
      let(:variant) { campaign_variant }

      it 'カートへリダイレクトしエラーを表示する。カートには追加されない' do
        create_line_item
        expect(response).to redirect_to(spree.cart_path(order_token: order.token))
        expect(flash[:error]).to eq error_message
        expect(order.reload.quantity_of(campaign_variant)).to eq 0
      end

      context 'turbo_stream の場合' do
        let(:headers) { { 'Accept' => Mime[:turbo_stream].to_s } }

        it 'エラーメッセージを返しカートには追加されない' do
          create_line_item
          expect(response.media_type).to eq Mime[:turbo_stream].to_s
          expect(response.body).to include(error_message)
          expect(order.reload.quantity_of(campaign_variant)).to eq 0
        end
      end
    end

    context '通常商品の場合' do
      let(:variant) { normal_variant }

      it 'カートに追加され、プロモーションがキャンペーン商品を追加する' do
        create_line_item
        order.reload
        expect(order.quantity_of(normal_variant)).to eq 1
        expect(order.quantity_of(campaign_variant)).to eq 1
      end
    end
  end

  describe 'PATCH update' do
    subject(:update_line_item) do
      patch "/line_items/#{line_item.id}",
            params: { order_token: order.token, line_item: { quantity: 9 } }
    end

    context 'キャンペーン商品の場合' do
      let!(:line_item) { create(:line_item, order: order, variant: campaign_variant, quantity: 5) }

      it 'カートへリダイレクトし数量が変更されない' do
        update_line_item
        expect(response).to redirect_to(spree.cart_path(order_token: order.token))
        expect(line_item.reload.quantity).to eq 5
      end
    end

    context '通常商品の場合' do
      let!(:line_item) { create(:line_item, order: order, variant: normal_variant, quantity: 1) }

      it '数量が変更される' do
        update_line_item
        expect(line_item.reload.quantity).to eq 9
      end
    end
  end

  describe 'DELETE destroy' do
    subject(:destroy_line_item) do
      delete "/line_items/#{line_item.id}", params: { order_token: order.token }
    end

    context 'キャンペーン商品の場合' do
      let!(:line_item) { create(:line_item, order: order, variant: campaign_variant) }

      it 'カートへリダイレクトし削除されない' do
        destroy_line_item
        expect(response).to redirect_to(spree.cart_path(order_token: order.token))
        expect(order.reload.line_items).to include(line_item)
      end
    end

    context '通常商品の場合' do
      let!(:line_item) { create(:line_item, order: order, variant: normal_variant) }

      it '削除される' do
        destroy_line_item
        expect(order.reload.line_items).not_to include(line_item)
      end
    end

    context 'プロモーションの条件の商品を削除した場合' do
      let(:line_item) { order.line_items.find_by!(variant: normal_variant) }

      before do
        rule = Spree::Promotion::Rules::Product.create!(promotion: promotion, preferred_match_policy: 'any')
        rule.product_ids = [ normal_variant.product_id ]
        post '/line_items', params: { order_token: order.token, variant_id: normal_variant.id, quantity: 1 }
      end

      it 'キャンペーン商品もカートから外れる' do
        expect(order.reload.quantity_of(campaign_variant)).to eq 1
        destroy_line_item
        expect(order.reload.quantity_of(campaign_variant)).to eq 0
      end
    end
  end
end
