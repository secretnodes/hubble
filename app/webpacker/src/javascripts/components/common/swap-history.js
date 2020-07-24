import moment from 'moment';
import Chart from 'chart.js';

class SwapHistory {
  constructor( target ) {
    this.target = target
  }

  render() {
    const data = App.seed.SWAP_HISTORY
    const format = 'MMM D'

    console.log(Object.keys(data));

    new Chart( this.target.get(0), {
      type: 'line',
      data: {
        labels: Object.keys(data),
        datasets: [
          {
            data: Object.values(data),
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
              const parts = _.compact( [
                `<label>Swaps:</label> ${item.yLabel}<br/>`,
                `<label>Date:</label> ${moment.utc(item.xLabel).format(format)}`
              ] )
              return parts.join('')
            }
          }
        },
        scales: {
          yAxes: [
            {
            }
          ],
          xAxes: [
            {
              type: 'time',
              distribution: 'linear',
              time: { unit: 'day' },

            }
          ]
        }
      }
    } )
  }
}

window.App.Common.SwapHistory = SwapHistory;
