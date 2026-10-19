# SpreePromotionActionCreateLineItems

`spree_promotion_action_create_line_items` locks the items that Spree's **Create line items**
promotion action adds to the cart.

Spree's action can add a free gift (a 0-priced product) to every cart that meets the
promotion's rules. Out of the box, though, customers can treat that gift like any other
product: put it in the cart on its own from the product page, change its quantity or remove
it. This extension leaves the gift entirely under the promotion's control.

## Features

A variant set on a Create line items action is a **campaign item**, whether or not the
promotion is currently active. For campaign items:

- The product page shows no add-to-cart button and no quantity selector (the product itself
  stays visible in search results and listings, so customers can see what they were given)
- The cart shows the quantity as plain text, with no remove button and no low-stock notice
- Requests sent directly are refused too: the storefront `POST /line_items`,
  `PATCH /line_items/:id` and `DELETE /line_items/:id`, and the Storefront API's
  `cart/add_item`, `cart/set_quantity` and `cart/remove_line_item` (422)

The promotion itself still adds and removes the item as usual — only customer actions are
blocked. Admins can still edit campaign items on orders in the Spree admin.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'spree_promotion_action_create_line_items'
```

Then run:

```bash
bundle install
```

No migration is needed — campaign items are read from Spree's own
`spree_promotion_action_line_items` table.

## Usage

Create a promotion in the Spree admin with the **Create line items** action and pick the
variant to add. That variant becomes a campaign item.

When the campaign ends, set the campaign product to draft or archived (or discontinue it).
Spree then removes it from any cart that still holds it the next time the customer opens the
cart or checkout. Customers cannot remove it themselves.

## Extending

Other promotion actions can mark their own variants as campaign items by prepending a module
to `Spree::Variant`:

```ruby
module MyPromotionAction
  module VariantDecorator
    def campaign_variant?
      super || MyPromotionActionLineItem.exists?(variant_id: id)
    end
  end
end

Spree::Variant.prepend(MyPromotionAction::VariantDecorator)
```

Require this gem before your own engine so that `super` is defined.

## Requirements

- Spree 5.3.6 (`spree_storefront` for the storefront screens)

## Licence

AGPL-3.0-or-later. See [LICENSE](LICENSE).
