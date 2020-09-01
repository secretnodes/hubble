import { Controller } from "stimulus"
import 'bootstrap/dist/js/bootstrap.bundle.min';
import 'datatables/media/js/jquery.dataTables.min';
import '../javascripts/components/common/transactions-table';
import '../javascripts/components/common/swap-history';

export default class extends Controller {
  connect() {
    this.load()

    if (this.data.has("refreshInterval")) {
      this.startRefreshing()
    }
  }

  disconnect() {
    this.stopRefreshing()
  }

  load() {
    fetch(this.data.get("url"))
      .then(response => response.text())
      .then(html => {
        this.element.innerHTML = html
        new App.Common.TransactionsTable( $('.transactions-table') ).render();

        if ( $('.swap-history-chart').html() != undefined ) {
          new App.Common.SwapHistory( $(`.swap-history-chart`) ).render()
        }
      })
  }

  startRefreshing() {
    this.refreshTimer = setInterval(() => {
      this.load()
    }, this.data.get("refreshInterval"))
  }

  stopRefreshing() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }
}