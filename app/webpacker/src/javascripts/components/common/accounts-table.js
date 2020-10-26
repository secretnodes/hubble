class AccountsTable {
  constructor( container ) {
    this.container = container
  }

  render() {
    const table = this.container.find('table')
    const isEmpty = table.data('empty')
    this.table = table.DataTable( {
      sDom: 'lrtip',
      paging: false,
      retrieve: true,
      info: false,
      autoWidth: false,
      className: 'transactions-table',
      stripeClasses: ['even', 'odd'],
      order: isEmpty ? [] : [ [2, 'desc'], [3, 'desc'] ],
      
      'columns': isEmpty ? [ { width: '45%' } ] : _.compact( [
        {
          width: 'auto',
          className: 'col-rank'
        },
        {
          width: 'auto',
          className: 'col-hash'
        },
        {
          width: 'auto',
          className: 'col-fee'
        },
        {
          width: 'auto',
          className: 'col-gas'
        }
      ] )
    } )
  }
}

window.App.Common.AccountsTable = AccountsTable