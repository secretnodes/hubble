class TransactionsTable {
  constructor( container ) {
    this.container = container
  }

  render() {
    this.table = this.container.find('table').DataTable( {
      sDom: 'lrtip',
      paging: false,
      info: false,
      autoWidth: false,
      className: 'transactions-table',
      order: [ [1, 'desc'], [2, 'desc'] ],
      'columns': _.compact( [
        {
          width: 'auto',
          className: 'col-hash'
        },
        {
          width: '150px',
          className: 'col-fee'
        },
        {
          width: '150px',
          className: 'col-gas'
        },
        {
          width: '150px',
          className: 'col-status'
        },
        {
          width: '150px',
          className: 'col-buttons',
          orderable: false
        }
      ] )
    } )
  }
}

window.App.Cosmos.TransactionsTable = TransactionsTable
