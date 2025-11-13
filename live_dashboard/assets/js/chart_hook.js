// Chart.js hook for LiveView
// This hook initializes and updates Chart.js charts based on data from the backend

export const ChartHook = {
  chart: null,
  
  async mounted() {
    // Load Chart.js from CDN if not already loaded
    if (typeof window.Chart === 'undefined') {
      await this.loadChartJS();
    }
    
    this.initChart();
  },
  
  updated() {
    // If chart exists, update it; otherwise initialize it
    if (this.chart) {
      this.updateChart();
    } else {
      this.initChart();
    }
  },
  
  destroyed() {
    if (this.chart) {
      this.chart.destroy();
      this.chart = null;
    }
  },
  
  async loadChartJS() {
    return new Promise((resolve, reject) => {
      if (typeof window.Chart !== 'undefined') {
        resolve();
        return;
      }
      
      const script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js';
      script.onload = () => resolve();
      script.onerror = () => reject(new Error('Failed to load Chart.js'));
      document.head.appendChild(script);
    });
  },
  
  initChart() {
    const canvas = this.el.querySelector('canvas');
    if (!canvas) return;
    
    const ctx = canvas.getContext('2d');
    const config = this.getChartConfig();
    
    this.chart = new window.Chart(ctx, config);
  },
  
  updateChart() {
    const config = this.getChartConfig();
    
    // Update chart data
    if (this.chart && config.data) {
      this.chart.data = config.data;
      this.chart.options = { ...this.chart.options, ...config.options };
      this.chart.update('none'); // 'none' mode for smoother updates
    }
  },
  
  getChartConfig() {
    const data = JSON.parse(this.el.dataset.chartData || '{}');
    const type = this.el.dataset.chartType || 'line';
    const options = JSON.parse(this.el.dataset.chartOptions || '{}');
    
    // Default options
    const defaultOptions = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: data.datasets && data.datasets.length > 1,
          position: 'top',
        },
        tooltip: {
          enabled: true,
        },
      },
      scales: type === 'line' || type === 'bar' ? {
        y: {
          beginAtZero: true,
          grid: {
            color: 'rgba(0, 0, 0, 0.1)',
          },
        },
        x: {
          grid: {
            color: 'rgba(0, 0, 0, 0.1)',
          },
        },
      } : undefined,
    };
    
    return {
      type: type,
      data: data,
      options: { ...defaultOptions, ...options },
    };
  },
};

