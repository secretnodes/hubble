import Ledger from '@lunie/cosmos-ledger';


$(document).ready( function() {
  if( !_.includes(App.mode, 'validator-show') ) { return }

  new App.Common.ValidatorVotingPowerHistory( $('.voting-power-history-chart') ).render()
  new App.Common.GovProposalsTable( $('.gov-proposals-table') ).render()
  new App.Common.DelegationsTable( $('.delegations-table') ).render()

  new App.Common.DelegationModal( $('#delegation-modal') )

  // 2 charts
  const charts = {
    last48h: null,
    alltime: null
  }

  new App.Common.ValidatorUptimeHistory( $(`.uptime-history-last48h-chart`), 'last48h' ).render()
  const API_URL = 'http://65.19.134.86:26657'
  const ADDRESS = "enigma1jk9zmatkhj2qh37j6ym9xt40s697adf5txv3z2"

  console.log(Buffer.from('abc'));

  const ledgerSigner = async () => {
    const signMessage = {} || ``
    console.log('inside ledger signer')
    const ledger = new Ledger(
       false,
      [44, 118, 0, 0, 0],
      'enigma'
      )

    console.log('after new Ledger')
    await ledger.connect()
    console.log('after ledger connect')
    const publicKey = await ledger.getPubKey()
    const publicAddress = await ledger.getCosmosAddress()
    const appInfo = await ledger.getOpenApp()
    console.log(publicAddress);
    console.log(publicKey);
    console.log(appInfo);
    return publicKey;
  }

  $('#ledger-test').click(function() {
    console.log('outside connectLedger')
    const publicKey = ledgerSigner()
  });

  // const switcherButtons = $('.validator-uptime-switcher button')

  // switcherButtons.click( ( e ) => {
  //   e.preventDefault()
  //   const button = $(e.currentTarget)
  //   const target = button.data('target')
  //   $(`.uptime-history-${target}-chart-container`).siblings().hide().end().show()
  //   charts[target] = charts[target] || new App.Common.ValidatorUptimeHistory( $(`.uptime-history-${target}-chart`), target ).render()
  //   button.siblings().removeClass('active').end().addClass('active')
  // } )
  // switcherButtons.first().trigger('click')

  // block heatmap
  const heatmap = $('.block-heatmap')
  const tooltipFn = window.customTooltip( { name: 'bhm', static: true, container: heatmap } )
  heatmap.find('.block').each( function() {
    const el = $(this)
    if( el.attr('title') ) {
      el.data('title', el.attr('title'))
      el.attr('title', null)
    }
  } ).hover(
    function( e ) {
      const blockEl = $(e.currentTarget)
      const tooltipEl = $(tooltipFn( {
        body: [ { lines: blockEl.data('title') } ]
      } ))
      blockEl.data( 'tooltip', tooltipEl )
    },
    function( e ) {
      const blockEl = $(e.currentTarget)
      const tooltipEl = blockEl.data('tooltip')
      blockEl.data('tooltip', null)
      if( tooltipEl ) { tooltipEl.remove() }
    }
  )
} )