/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

console.log('Hello World from Webpacker')
import '../src/javascripts/components/admin/cosmos-chain-validator-event-definitions.js';
import '../src/javascripts/components/admin/delete-confirmation.js';
import '../src/javascripts/components/common/auto-alert-hide.js';
import '../src/javascripts/components/common/delegation-modal.js';
import '../src/javascripts/components/common/delegations-table.js';
import '../src/javascripts/components/common/gov-proposal-deposit-modal.js';
import '../src/javascripts/components/common/gov-proposal-submit-modal.js';
import '../src/javascripts/components/common/gov-proposal-vote-modal.js';
import '../src/javascripts/components/common/gov-proposals-table.js';
import '../src/javascripts/components/common/ledger.js';
import '../src/javascripts/components/common/small-average-block-time-chart.js';
import '../src/javascripts/components/common/small-average-voting-power-chart.js';
import '../src/javascripts/components/common/tiny-average-active-validators-chart.js';
import '../src/javascripts/components/common/transactions-table.js';
import '../src/javascripts/components/common/validator-table.js';
import '../src/javascripts/components/common/validator-uptime-history.js';
import '../src/javascripts/components/common/validator-voting-power-history.js';
import '../src/javascripts/lib/bech32.js';
import 'bops/dist/bops';
import '../src/javascripts/lib/Chart.min.js';
import '../src/javascripts/lib/chartjs-plugin-annotation.min.js';
import '../src/javascripts/lib/chrome-u2f-api.js';
import '../src/javascripts/lib/custom-tooltip.js';
import '../src/javascripts/lib/elliptic.js';
import '../src/javascripts/lib/ledger-lunie.js';
import '../src/javascripts/lib/ledger.js';
import '../src/javascripts/lib/money.js';
import '../src/javascripts/lib/scale.js';
import '../src/javascripts/lib/uuid.js';
import '../src/javascripts/page/common/account-show.js';
import '../src/javascripts/page/common/block-show.js';
import '../src/javascripts/page/common/chain-halted.js';
import '../src/javascripts/page/common/dashboard.js';
import '../src/javascripts/page/common/faucet-show.js';
import '../src/javascripts/page/common/faucet-transaction-show.js';
import '../src/javascripts/page/common/governance-index.js';
import '../src/javascripts/page/common/governance-proposal.js';
import '../src/javascripts/page/common/validator-show.js';
import '../src/javascripts/page/common/validator-subscriptions.js';
import '../src/javascripts/page/admin-init.js';
import '../src/javascripts/page/app-init.js';
import '../src/javascripts/account.js';
import '../src/javascripts/admin.js';
import '../src/javascripts/cosmos.js';
import '../src/javascripts/enigma.js';
import '../src/javascripts/iris.js';
import '../src/javascripts/kava.js';
import '../src/javascripts/terra.js';
import 'bootstrap/dist/js/bootstrap';


require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()

require.context('../images', true);