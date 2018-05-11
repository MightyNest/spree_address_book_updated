//= require spree/backend
$(function() {
  if ($('#customer_search').is('*')) {
    //UPGRADE: select2 3.5 has different events
    $("#customer_search").on('select2-selecting', function(e) {
      if(e.object && e.object.addresses && e.object.addresses.length > 0) {
        var addressHtml = '<option value="">Add a New Address</option>';
        for (var i = 0, len = e.object.addresses.length; i < len; i++) {
          var address = e.object.addresses[i];
          addressHtml += '<option value="' + address.id + '">' + address.address1 + ' ' + address.zipcode + '</option>';
        }

        $('#order_bill_address_id').html(addressHtml);
        $('#order_ship_address_id').html(addressHtml);
      }
    });

    var togglePanel = function(val, panelSel) {
      if (val == '') {
        $(panelSel).show();
        $(panelSel).find('input').prop('disabled', false);
      }else {
        $(panelSel).hide();
        $(panelSel).find('input').prop('disabled', true);
      }
    };

    var setupToggle = function(select, panelSel) {
      $(select).on('select2-selecting', function(e) {
        togglePanel(e.val, panelSel);
      });
      togglePanel($(select).val(), panelSel);
    };

    setupToggle('#order_bill_address_id', '[data-hook="bill_address_wrapper"] > .panel');
    setupToggle('#order_ship_address_id', '[data-hook="ship_address_wrapper"] > .panel');
  }
});