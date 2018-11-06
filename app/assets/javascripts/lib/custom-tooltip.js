window.customTooltip = function( options ) {
  options = options ? options : { name: 'default' }

  return function( tooltip ) {
    let container, width, height, positionX, positionY
    if( this._chart ) {
      container = this._chart.canvas
      width = container.width
      height = container.height
      positionX = container.offsetLeft
      positionY = container.offsetTop
    }
    else {
      container = options.container.get(0)
      width = options.container.width()
      height = options.container.height()
      positionX = 0
      positionY = 0
    }

    let tooltipEl = document.getElementById('chartjs-tooltip-'+options.name);

    if (!tooltipEl) {
      tooltipEl = document.createElement('div');
      tooltipEl.id = 'chartjs-tooltip-'+options.name;
      tooltipEl.classList.add('chartjs-tooltip');
      tooltipEl.innerHTML = '<div></div>';
      container.parentNode.appendChild(tooltipEl);
    }

    // Hide if no tooltip
    if (tooltip.opacity === 0) {
      tooltipEl.style.opacity = 0;
      return;
    }

    // Set caret Position
    tooltipEl.classList.remove('above', 'below', 'no-transform');
    if (tooltip.yAlign) {
      tooltipEl.classList.add(tooltip.yAlign);
    } else {
      tooltipEl.classList.add('no-transform');
    }

    // Set Text
    if (tooltip.body) {
      var innerHtml = tooltip.body.map(i => i.lines).join('');
      var root = tooltipEl.querySelector('div:first-child');
      root.innerHTML = innerHtml;
    }

    // Display, position, and set styles for font
    tooltipEl.style.opacity = 1;

    if( options.static ) {
      tooltipEl.classList.add('static-tooltip')
      tooltipEl.style.left = positionX + ((width / window.devicePixelRatio) / 2) + 'px'
      tooltipEl.style.top = positionY + (height / window.devicePixelRatio) + 3 + 'px'
    }
    else {
      tooltipEl.style.left = positionX + tooltip.caretX + 'px';
      tooltipEl.style.top = positionY + (options.top || 0) + tooltip.caretY + 'px';
    }
    if( options.minWidth ) { tooltipEl.style.minWidth = options.minWidth + 'px' }

    return tooltipEl
  }
}
