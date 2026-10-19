require 'spec_helper'

RSpec.describe Spree::Variant, type: :model do
  let!(:store) { create(:store) }

  describe '#campaign_variant?' do
    let(:campaign_variant) { create(:product).master }
    let(:normal_variant) { create(:product).master }

    before do
      action = create(:promotion_action_create_line_items)
      action.promotion_action_line_items.create!(variant: campaign_variant, quantity: 1)
    end

    it 'CreateLineItemsアクションに設定されたバリアントはtrueを返す' do
      expect(campaign_variant.campaign_variant?).to be true
    end

    it '設定されていないバリアントはfalseを返す' do
      expect(normal_variant.campaign_variant?).to be false
    end
  end
end
