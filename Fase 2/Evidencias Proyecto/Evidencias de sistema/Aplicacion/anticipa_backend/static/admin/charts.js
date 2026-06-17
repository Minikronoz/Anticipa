// charts.js - Gráficos adicionales para dashboard

const API = 'https://anticipa.onrender.com';

async function crearGraficoDesregulacion() {
    const canvas = document.getElementById('graficoDesregulacion');
    if (!canvas) return;

    try {
        const res = await fetch(`${API}/reportes/dashboard`);
        if (!res.ok) throw new Error();
        const data = await res.json();

        new Chart(canvas, {
            type: 'line',
            data: {
                labels: data.evolucion.labels || ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'],
                datasets: [{
                    label: 'Desregulaciones',
                    data: data.evolucion.data || [0, 0, 0, 0, 0, 0],
                    borderColor: '#E53935',
                    backgroundColor: 'rgba(229, 57, 53, 0.1)',
                    fill: true,
                    tension: 0.4,
                    borderWidth: 3
                }]
            },
            options: {
                responsive: true,
                plugins: { legend: { position: 'bottom' } },
                scales: { y: { beginAtZero: true } }
            }
        });
    } catch (error) {
        console.log('No se pudo cargar el gráfico de desregulación');
    }
}
