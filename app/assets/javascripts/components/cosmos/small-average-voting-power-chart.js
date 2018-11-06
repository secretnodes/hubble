class SmallAverageVotingPowerChart {
  constructor( target, interval ) {
    this.target = target
    this.interval = interval
  }

  render() {
    const data = App.seed.AVERAGE_VOTING_POWER[this.interval]
    const format = this.interval == 'last48h' ? 'k:mm' : 'MMM D'

    if( !data || _.isEmpty(data) ) {
      this.target.parent().hide()
      return
    }

    new Chart( this.target.get(0), {
      type: 'line',
      data: {
        labels: _.map( data, dp => dp.t ),
        datasets: [
          {
            cubicInterpolationMode: 'monotone',
            data: data,
            borderColor: "#70707a",
            fill: false
          }
        ]
      },
      options: {
        elements: {
          point: { radius: 0, backgroundColor: '#70707a', hitRadius: 6, hoverRadius: 3 }
        },
        layout: {
          padding: { top: 5, bottom: 5, left: 5, right: 5 }
        },
        maintainAspectRatio: false,
        legend: { display: false },
        title: { display: false },
        hover: {
          mode: 'nearest',
          intersect: false
        },
        tooltips: {
          enabled: false,
          mode: 'nearest',
          intersect: false,
          custom: window.customTooltip( { name: `sm-va-${this.interval}`, static: true } ),
          callbacks: {
            label: ( item, data ) => {
              const date = data.datasets[item.datasetIndex].data[item.index].t
              return `${item.yLabel.toFixed(0)} voting power ` +
                     `${this.interval == 'last30d' ? 'on' : 'at'} ` +
                     `${moment.utc(date).format(format)}`
            }
          }
        },
        scales: {
          yAxes: [
            {
              display: false,
              ticks: { display: false, stepSize: 1 }
            }
          ],
          xAxes: [
            {
              display: false,
              ticks: {
                display: false,
                callback: ( date ) => moment(date).format("MMM-D hh:mm")
              }
            }
          ]
        }
      }
    } )
  }
}

window.App.Cosmos.SmallAverageVotingPowerChart = SmallAverageVotingPowerChart
