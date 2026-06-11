const API = 'https://anticipa.onrender.com';

let usuarios = [];

function getSesion() {
    const data = localStorage.getItem('adminSesion');
    return data ? JSON.parse(data) : null;
}

function nombreRol(id) {
    switch (id) {
        case 1:
            return 'Administrador';
        case 2:
            return 'Profesor';
        case 3:
            return 'Tutor';
        case 4:
            return 'Estudiante';
        default:
            return 'Desconocido';
    }
}

// =========================
// LOGIN
// =========================

async function login(e) {
    e.preventDefault();

    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const error = document.getElementById('error');

    error.classList.add('d-none');

    try {

        const res = await fetch(`${API}/admin/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email,
                password
            })
        });

        const data = await res.json();

        if (!res.ok) {
            error.textContent =
                data.detail || 'Credenciales incorrectas';
            error.classList.remove('d-none');
            return;
        }

        localStorage.setItem(
            'adminSesion',
            JSON.stringify(data)
        );

        window.location.href = 'dashboard.html';

    } catch (err) {

        error.textContent =
            'Error de conexión con el servidor';

        error.classList.remove('d-none');
    }
}

// =========================
// USUARIOS
// =========================

async function cargarUsuarios() {

    try {

        const res = await fetch(
            `${API}/admin/usuarios/`
        );

        if (!res.ok) {
            throw new Error('Error al obtener usuarios');
        }

        usuarios = await res.json();

        renderTabla(usuarios);

        actualizarMetricas();

    } catch (err) {

        console.error(err);

        alert(
            'No fue posible cargar los usuarios'
        );
    }
}

function renderTabla(lista) {

    const tbody =
        document.getElementById('tablaUsuarios');

    if (!tbody) return;

    tbody.innerHTML = lista.map(u => `
        <tr>
            <td>${u.id_usuario}</td>
            <td>${u.nombre}</td>
            <td>${u.email}</td>
            <td>${nombreRol(u.rol_id_rol)}</td>
            <td>${u.es_admin ? '✅' : '❌'}</td>
            <td>${u.curso_id_curso || '-'}</td>
            <td>
                <button
                    class="btn btn-sm btn-primary"
                    onclick="abrirEditar(${u.id_usuario})"
                >
                    ✏️
                </button>

                <button
                    class="btn btn-sm btn-danger"
                    onclick="eliminarUsuario(${u.id_usuario})"
                >
                    🗑️
                </button>
            </td>
        </tr>
    `).join('');
}

function filtrarUsuarios() {

    const texto =
        document
            .getElementById('buscar')
            .value
            .toLowerCase();

    const filtrados =
        usuarios.filter(u =>
            u.nombre.toLowerCase().includes(texto) ||
            u.email.toLowerCase().includes(texto)
        );

    renderTabla(filtrados);
}

// =========================
// MÉTRICAS
// =========================

function actualizarMetricas() {

    const estudiantes =
        usuarios.filter(
            u => Number(u.rol_id_rol) === 4
        ).length;

    const profesores =
        usuarios.filter(
            u => Number(u.rol_id_rol) === 2
        ).length;

    const tutores =
        usuarios.filter(
            u => Number(u.rol_id_rol) === 3
        ).length;

    const admins =
        usuarios.filter(
            u => u.es_admin === true
        ).length;

    document.getElementById('totalUsuarios').textContent =
        usuarios.length;

    document.getElementById('totalEstudiantes').textContent =
        estudiantes;

    document.getElementById('totalProfesores').textContent =
        profesores;

    document.getElementById('totalTutores').textContent =
        tutores;

    document.getElementById('totalAdmins').textContent =
        admins;
}


// =========================
// CREAR USUARIO
// =========================

async function crearUsuario() {

    const datos = {

        nombre:
            document.getElementById('nuevoNombre').value,

        email:
            document.getElementById('nuevoEmail').value,

        password:
            document.getElementById('nuevoPassword').value,

        rol_id_rol:
            parseInt(
                document.getElementById('nuevoRol').value
            ),

        es_admin:
            parseInt(
                document.getElementById('nuevoRol').value
            ) === 1
    };

    try {

        const res = await fetch(
            `${API}/admin/usuarios`,
            {
                method: 'POST',
                headers: {
                    'Content-Type':
                        'application/json'
                },
                body: JSON.stringify(datos)
            }
        );

        const data = await res.json();

        if (!res.ok) {
            alert(data.detail);
            return;
        }

        bootstrap.Modal
            .getInstance(
                document.getElementById('modalCrear')
            )
            .hide();

        document.getElementById('nuevoNombre').value = '';
        document.getElementById('nuevoEmail').value = '';
        document.getElementById('nuevoPassword').value = '';

        await cargarUsuarios();

        alert('Usuario creado correctamente');

    } catch (err) {

        alert(
            'Error al crear usuario'
        );
    }
}


// =========================
// EDITAR
// =========================

function abrirEditar(id) {

    const u =
        usuarios.find(
            usuario => usuario.id_usuario === id
        );

    if (!u) return;

    document.getElementById('editId').value =
        u.id_usuario;

    document.getElementById('editNombre').value =
        u.nombre;

    document.getElementById('editEmail').value =
        u.email;

    document.getElementById('editRol').value =
        u.rol_id_rol;

    document.getElementById('editAdmin').checked =
        u.es_admin;

    document.getElementById('editPassword').value =
        '';

    new bootstrap.Modal(
        document.getElementById('modalEditar')
    ).show();
}

async function guardarUsuario() {

    const id =
        document.getElementById('editId').value;

    const datos = {};

    const nombre =
        document.getElementById('editNombre').value;

    const email =
        document.getElementById('editEmail').value;

    const rol =
        document.getElementById('editRol').value;

    const admin =
        document.getElementById('editAdmin').checked;

    const password =
        document.getElementById('editPassword').value;

    if (nombre) datos.nombre = nombre;

    if (email) datos.email = email;

    if (rol)
        datos.rol_id_rol = parseInt(rol);

    datos.es_admin = admin;

    if (password)
        datos.password = password;

    try {

        const res = await fetch(
            `${API}/admin/usuarios/${id}`,
            {
                method: 'PATCH',
                headers: {
                    'Content-Type':
                        'application/json'
                },
                body: JSON.stringify(datos)
            }
        );

        if (!res.ok) {
            throw new Error();
        }

        bootstrap.Modal
            .getInstance(
                document.getElementById('modalEditar')
            )
            .hide();

        await cargarUsuarios();

    } catch (err) {

        alert(
            'No fue posible actualizar el usuario'
        );
    }
}

// =========================
// ELIMINAR
// =========================

async function eliminarUsuario(id) {

    const confirmar = confirm(
        '¿Estás seguro de eliminar este usuario?'
    );

    if (!confirmar) return;

    try {

        const res = await fetch(
            `${API}/admin/usuarios/${id}`,
            {
                method: 'DELETE'
            }
        );

        if (!res.ok) {
            throw new Error();
        }

        await cargarUsuarios();

    } catch (err) {

        alert(
            'No fue posible eliminar el usuario'
        );
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
// INICIALIZACIÓN
// =========================

document.addEventListener(
    'DOMContentLoaded',
    () => {

        const ruta =
            window.location.pathname;

        if (
            ruta.includes('dashboard.html') ||
            ruta.includes('usuarios.html')
        ) {

            if (!getSesion()) {

                window.location.href =
                    'index.html';

                return;
            }

            cargarUsuarios();
        }

        if (
            ruta.endsWith('index.html') ||
            ruta.endsWith('/admin/') ||
            ruta.endsWith('/admin')
        ) {

            if (getSesion()) {

                window.location.href =
                    'dashboard.html';

                return;
            }

            document
                .getElementById('loginForm')
                ?.addEventListener(
                    'submit',
                    login
                );
        }
    }
);