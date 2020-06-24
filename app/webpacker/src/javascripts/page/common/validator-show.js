

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