Deface::Override.new(
  :virtual_path => "spree/admin/orders/customer_details/_form",
  :name => "address_book_existing_addresses",
  :insert_after => "[data-hook='customer_guest']",
  :partial => "spree/admin/orders/customer_details/existing_addresses",
  :disabled => false
)
