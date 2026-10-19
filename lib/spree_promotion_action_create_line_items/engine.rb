module SpreePromotionActionCreateLineItems
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_promotion_action_create_line_items'

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.after_initialize do
      ActionView::Base.include SpreePromotionActionCreateLineItems::LineItemsHelper
    end

    initializer 'spree_promotion_action_create_line_items.deface_overrides' do |_app|
      if Rails.autoloaders.zeitwerk_enabled?
        Rails.autoloaders.main.ignore("#{root}/app/overrides")
      end
    end

    config.to_prepare(&method(:activate).to_proc)
  end
end
