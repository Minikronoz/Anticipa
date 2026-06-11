const API = 'https://anticipa.onrender.com';

let usuarios = [];
let sesion = null;

function getSesion() {
    const data = localStorage.getItem('adminSesion');
    return data ? JSON.parse(data) : null;
}

async function login(e) {
    e.preventDefault();
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const error = document.getElementById('error');

    try {
        const res = await fetch(`${API}/admin/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
        });
        if (!res.ok) {
            const data = await res.json();
            error.textContent = data.detail || 'Error';
            error.classList.remove('d-none');
            return;
        }
        const data = await res.json();
        localStorage.setItem('adminSesion', JSON.stringify(data));
        window.location.href = 'dashboard.html';
    } catch (err) {
        error.textContent = 'Error de conexión';
        error.classList.remove('d-none');
    }
}

async function cargarUsuarios() {
    const res = await fetch(`${API}/admin/usuarios/`);
    usuarios = await res.json();
    renderTabla(usuarios);
}

function renderTabla(lista) {
    const tbody = document.getElementById('tablaUsuarios');
    tbody.innerHTML = lista.map(u => `
        <tr>
            <td>${u.id_usuario}</td>
            <td>${u.nombre}</td>
            <td>${u.email}</td>
            <td>${u.rol_id_rol}</td>
            <td>${u.es_admin ? '✅' : '❌'}</td>
            <td>${u.curso_id_curso || '-'}</td>
            <td>
                <button class="btn btn-sm btn-primary" onclick="abrirEditar(${u.id_usuario})">✏️</button>
                <button class="btn btn-sm btn-danger" onclick="eliminarUsuario(${u.id_usuario})">🗑️</button>
            </td>
        </tr>
    `).join('');
}

function filtrarUsuarios() {
    const texto = document.getElementById('buscar').value.toLowerCase();
    const filtrados = usuarios.filter(u =>
        u.nombre.toLowerCase().includes(texto) ||
        u.email.toLowerCase().includes(texto)
    );
    renderTabla(filtrados);
}

function abrirEditar(id) {
    const u = usuarios.find(x => x.id_usuario === id);
    document.getElementById('editId').value = u.id_usuario;
    document.getElementById('editNombre').value = u.nombre;
    document.getElementById('editEmail').value = u.email;
    document.getElementById('editRol').value = u.rol_id_rol;
    document.getElementById('editAdmin').checked = u.es_admin;
    document.getElementById('editPassword').value = '';
    new bootstrap.Modal(document.getElementById('modalEditar')).show();
}

async function guardarUsuario() {
    const id = document.getElementById('editId').value;
    const datos = {};
    const nombre = document.getElementById('editNombre').value;
    const email = document.getElementById('editEmail').value;
    const rol = document.getElementById('editRol').value;
    const admin = document.getElementById('editAdmin').checked;
    const password = document.getElementById('editPassword').value;

    if (nombre) datos.nombre = nombre;
    if (email) datos.email = email;
    if (rol) datos.rol_id_rol = parseInt(rol);
    datos.es_admin = admin;
    if (password) datos.password = password;

    await fetch(`${API}/admin/usuarios/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(datos)
    });
    bootstrap.Modal.getInstance(document.getElementById('modalEditar')).hide();
    cargarUsuarios();
}

async function eliminarUsuario(id) {
    if (!confirm('¿Estás seguro de eliminar este usuario?')) return;
    await fetch(`${API}/admin/usuarios/${id}`, { method: 'DELETE' });
    cargarUsuarios();
}

function logout() {
    localStorage.removeItem('adminSesion');
    window.location.href = 'index.html';
}

// Inicializar
document.addEventListener('DOMContentLoaded', () => {
    if (window.location.pathname.endsWith('dashboard.html')) {
        if (!getSesion()) { window.location.href = 'index.html'; return; }
        cargarUsuarios();
    }
    if (window.location.pathname.endsWith('index.html') || window.location.pathname === '/admin/') {
        if (getSesion()) { window.location.href = 'dashboard.html'; return; }
        document.getElementById('loginForm')?.addEventListener('submit', login);
    }
});