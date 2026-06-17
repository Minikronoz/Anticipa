// charts.js - Gráficos adicionales para dashboard
// Este archivo contiene funciones de gráficos complementarias

// Gráfico de desregulaciones (pendiente de datos del backend)
function crearGraficoDesregulacion(data) {
    const canvas = document.getElementById('graficoDesregulacion');
    if (!canvas) return;
    // Placeholder: awaiting backend endpoint for desregulacion data
    new Chart(canvas, {
        type: 'line',
        data: {
            labels: data.labels || ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'],
            datasets: [{
                label: 'Desregulaciones',
                data: data.valores || [0, 0, 0, 0],
                borderColor: '#E53935',
                backgroundColor: 'rgba(229, 57, 53, 0.1)',
                fill: true,
                tension: 0.4
            }]
        },
        options: {
            responsive: true,
            plugins: { legend: { position: 'bottom' } },
            scales: { y: { beginAtZero: true } }
        }
    });
}
