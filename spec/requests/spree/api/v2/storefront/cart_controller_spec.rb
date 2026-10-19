require 'spec_helper'

# キャンペーンバリアント（CreateLineItems アクションで設定されたバリアント）に対する
# add_item / remove_line_item / set_quantity を 422 で拒否することを担保する。
RSpec.describe 'Storefront API V2 Cart campaign guard', type: :request do
  let!(:store) { create(:store) }
  let(:order) { create(:order, store: store, state: 'cart', completed_at: nil) }
  let(:headers) { { 'X-Spree-Order-Token' => order.token } }

  let(:campaign_variant) { create(:product).master }
  let(:normal_variant) { create(:product).master }
  let(:error_message) { Spree.t('campaign_line_item.cannot_modify') }

  def json_response
    JSON.parse(response.body)
  end

  before do
    host! 'test.localhost'
    # current_store は request の SERVER_NAME から解決されるため、対象 store を返すようスタブする（Spree 本家の cart_spec と同じ方式）。
    allow_any_instance_of(Spree::Api::V2::Storefront::CartController)
      .to receive(:current_store).and_return(store)
    action = create(:promotion_action_create_line_items)
    action.promotion_action_line_items.create!(variant: campaign_variant, quantity: 1)
  end

  describe 'cart#add_item' do
    subject(:add_item) do
      post '/api/v2/storefront/cart/add_item',
           params: { variant_id: variant.id, quantity: 1 }, headers: headers
    end

    context 'キャンペーンバリアントの場合' do
      let(:variant) { campaign_variant }

      it '422を返しカートに追加されない' do
        add_item
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq error_message
        expect(order.reload.quantity_of(campaign_variant)).to eq 0
      end
    end

    context '通常バリアントの場合' do
      let(:variant) { normal_variant }

      it 'カートに追加される' do
        add_item
        expect(response).to have_http_status(:ok)
        expect(order.reload.quantity_of(normal_variant)).to eq 1
      end
    end
  end

  describe 'cart#remove_line_item' do
    subject(:remove_line_item) do
      delete "/api/v2/storefront/cart/remove_line_item/#{line_item.id}", headers: headers
    end

    context 'キャンペーン商品のラインアイテムの場合' do
      let!(:line_item) { create(:line_item, order: order, variant: campaign_variant) }

      it '422を返し削除されない' do
        remove_line_item
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq error_message
        expect(order.reload.line_items).to include(line_item)
      end
    end

    context '通常商品のラインアイテムの場合' do
      let!(:line_item) { create(:line_item, order: order, variant: normal_variant) }

      it '削除される' do
        remove_line_item
        expect(response).to have_http_status(:ok)
        expect(order.reload.line_items).not_to include(line_item)
      end
    end
  end

  describe 'cart#set_quantity' do
    subject(:set_quantity) do
      patch '/api/v2/storefront/cart/set_quantity',
            params: { line_item_id: line_item.id, quantity: 9 }, headers: headers
    end

    context 'キャンペーン商品のラインアイテムの場合' do
      let!(:line_item) { create(:line_item, order: order, variant: campaign_variant, quantity: 5) }

      it '422を返し数量が変更されない' do
        set_quantity
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq error_message
        expect(line_item.reload.quantity).to eq 5
      end
    end

    context '通常商品のラインアイテムの場合' do
      let!(:line_item) { create(:line_item, order: order, variant: normal_variant, quantity: 1) }

      it '数量が変更される' do
        set_quantity
        expect(response).to have_http_status(:ok)
        expect(line_item.reload.quantity).to eq 9
      end
    end
  end
end
