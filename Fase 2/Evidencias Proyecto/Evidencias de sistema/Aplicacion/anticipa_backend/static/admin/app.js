const API = 'https://anticipa.onrender.com';
console.log("USUARIOSJS CARGADO");

// =========================
// SESIÓN
// =========================

function getSesion() {
    const data = localStorage.getItem('adminSesion');
    return data ? JSON.parse(data) : null;
}

// =========================
// LOGIN
// =========================

async function login(e) {

    e.preventDefault();

    const email =
        document.getElementById('email').value;

    const password =
        document.getElementById('password').value;

    const error =
        document.getElementById('error');

    error.classList.add('d-none');

    try {

        const res = await fetch(
            `${API}/admin/login`,
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    email,
                    password
                })
            }
        );

        const data = await res.json();

        if (!res.ok) {

            error.textContent =
                data.detail ||
                'Credenciales incorrectas';

            error.classList.remove('d-none');
            return;
        }

        localStorage.setItem(
            'adminSesion',
            JSON.stringify(data)
        );

        window.location.href =
            'dashboard.html';

    } catch (err) {

        error.textContent =
            'Error de conexión con el servidor';

        error.classList.remove('d-none');
    }
}

// =========================
// LOGOUT
// =========================

function logout() {

    localStorage.removeItem(
        'adminSesion'
    );

    window.location.href =
        'index.html';
}

// =========================
// DASHBOARD
// =========================

async function cargarDashboard() {

    try {

        const res = await fetch(
            `${API}/admin/estadisticas`
        );

        if (!res.ok) {
            throw new Error();
        }

        const data = await res.json();

        const totalUsuarios =
            document.getElementById('totalUsuarios');

        const totalEstudiantes =
            document.getElementById('totalEstudiantes');

        const totalProfesores =
            document.getElementById('totalProfesores');

        const totalTutores =
            document.getElementById('totalTutores');

        if (totalUsuarios)
            totalUsuarios.textContent =
                data.total_usuarios || 0;

        if (totalEstudiantes)
            totalEstudiantes.textContent =
                data.estudiantes || 0;

        if (totalProfesores)
            totalProfesores.textContent =
                data.profesores || 0;

        if (totalTutores)
            totalTutores.textContent =
                data.tutores || 0;

        if (
            typeof Chart !== "undefined" &&
            document.getElementById('graficoRoles')
        ) {
            crearGraficoRoles(data);
        }

        if (
            typeof Chart !== "undefined" &&
            document.getElementById('graficoDesregulacion') &&
            typeof crearGraficoDesregulacion === "function"
        ) {
            crearGraficoDesregulacion();
        }

    } catch (error) {

        console.error(error);

        alert(
            'No fue posible cargar el dashboard'
        );
    }
}

// =========================
// GRÁFICO
// =========================

function crearGraficoRoles(data) {

    const canvas =
        document.getElementById(
            'graficoRoles'
        );

    if (!canvas) return;

    new Chart(canvas, {

        type: 'doughnut',

        data: {

            labels: [
                'Administradores',
                'Profesores',
                'Tutores',
                'Estudiantes'
            ],

            datasets: [{
                data: [
                    data.administradores || 0,
                    data.profesores || 0,
                    data.tutores || 0,
                    data.estudiantes || 0
                ],
                backgroundColor: [
                    '#1565C0',
                    '#43A047',
                    '#FB8C00',
                    '#E53935'
                ]
            }]
        },

        options: {

            responsive: true,

            plugins: {

                legend: {
                    position: 'bottom'
                }
            }
        }
    });
}

// =========================
// INICIO
// =========================

document.addEventListener(
    'DOMContentLoaded',
    () => {

        const ruta =
            window.location.pathname;

        const loginForm =
            document.getElementById(
                'loginForm'
            );

        if (loginForm) {

            loginForm.addEventListener(
                'submit',
                login
            );
        }

        if (
            ruta.includes('dashboard.html')
        ) {

            if (!getSesion()) {

                window.location.href =
                    'index.html';

                return;
            }

            cargarDashboard();
        }
    }
);