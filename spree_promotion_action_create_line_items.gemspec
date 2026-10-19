# encoding: UTF-8

lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'spree_promotion_action_create_line_items/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_promotion_action_create_line_items'
  s.version     = SpreePromotionActionCreateLineItems::VERSION
  s.summary     = 'Lock the items a promotion adds to the cart'
  s.description = 'Treats the variants set on the "Create line items" promotion action as campaign items: ' \
                  'customers cannot add them to the cart themselves, change their quantity or remove them, ' \
                  'so the promotion stays in control of them.'
  s.required_ruby_version = '>= 3.1.4'

  s.author      = 'be agile Co., Ltd.'
  s.email       = 'develop@be-agile.jp'
  s.homepage    = 'https://github.com/be-agile/spree_promotion_action_create_line_items'
  s.licenses    = [ 'AGPL-3.0-or-later' ]

  s.files       = Dir['{app,config,lib}/**/*', 'LICENSE', 'README.md']
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree', '= 5.3.6'
  s.add_dependency 'spree_storefront', '= 5.3.6'
  s.add_dependency 'spree_extension', '= 0.1.0'
  s.add_dependency 'deface'
end
