import moment from 'moment';
import Chart from 'chart.js';

class ValidatorUptimeHistory {
  constructor( target, interval ) {
    this.target = target
    this.interval = interval
  }

  render() {
    const data = App.seed.UPTIME_HISTORY[this.interval]
    const format = this.interval == 'last48h' ? 'k:mm' : 'MMM D'

    new Chart( this.target.get(0), {
      type: 'line',
      data: {
        labels: _.pick( data, 't' ),
        datasets: [
          {
            data: data.map( (dp) =>
              _.merge( {}, dp, { y: Math.round(dp.y * 100) } )
            ),
            borderColor: '#70707a',
            fill: false,
            cubicInterpolationMode: 'monotone',
            steppedLine: false
          }
        ]
      },
      options: {
        elements: {
          point: { radius: 2, backgroundColor: '#70707a', hitRadius: 6, hoverRadius: 3 }
        },
        maintainAspectRatio: false,
        legend: { display: false },
        title: { display: false },
        hover: {
          mode: 'nearest',
          intersect: true
        },
        tooltips: {
          enabled: false,
          mode: 'nearest',
          intersect: true,
          custom: window.customTooltip( { minWidth: 250, top: 3, name: `t-vuh-${this.interval}` } ),
          callbacks: {
            label: ( item, data ) => {
              const date = data.datasets[item.datasetIndex].data[item.index].t
              const parts = _.compact( [
                `<label>Average Uptime:</label> ${item.yLabel}%<br/>`,
                `<label>${this.interval == 'alltime' ? 'Date' : 'Time'}:</label> ${moment.utc(date).format(format)}`
              ] )
              return parts.join('')
            }
          }
        },
        scales: {
          yAxes: [
            {
              ticks: {
                max: 100, min: 0,
                stepSize: 100
              }
            }
          ],
          xAxes: [
            {
              type: 'time',
              distribution: 'linear',
              time: { unit: 'day' },
              ticks: { maxRotation: 0, autoSkip: true }
            }
          ]
        }
      }
    } )
  }
}

window.App.Common.ValidatorUptimeHistory = ValidatorUptimeHistory
