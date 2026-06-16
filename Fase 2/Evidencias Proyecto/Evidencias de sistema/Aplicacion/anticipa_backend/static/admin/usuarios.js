const API = 'https://anticipa.onrender.com';

let usuarios = [];

// =========================
// DOMINIOS
// =========================

function actualizarDominio() {

    const dominio =
        document.getElementById(
            "nuevoDominio"
        );

    const preview =
        document.getElementById(
            "dominioPreview"
        );

    if(!dominio || !preview){
        return;
    }

    preview.textContent =
        dominio.value;
}
// =========================
// ROLES
// =========================

function nombreRol(id) {

    switch (Number(id)) {

        case 1:
            return '<span class="badge bg-primary">Administrador</span>';

        case 2:
            return '<span class="badge bg-success">Profesor</span>';

        case 3:
            return '<span class="badge bg-warning text-dark">Tutor</span>';

        case 4:
            return '<span class="badge bg-secondary">Estudiante</span>';

        default:
            return '<span class="badge bg-dark">Sin rol</span>';
    }
}

// =========================
// CARGAR USUARIOS
// =========================

async function cargarUsuarios() {

    try {

        const res = await fetch(
            `${API}/admin/usuarios/`
        );

        if (!res.ok) {
            throw new Error(
                'Error cargando usuarios'
            );
        }

        usuarios = await res.json();

        renderTabla(usuarios);

        actualizarMetricas();

    } catch (error) {

        console.error(error);

        alert(
            'No fue posible cargar los usuarios'
        );
    }
}

// =========================
// TABLA
// =========================

function renderTabla(lista) {

    const tabla =
        document.getElementById(
            'tablaUsuarios'
        );

    if (!tabla) return;

    tabla.innerHTML = '';

    lista.forEach(usuario => {

        tabla.innerHTML += `

        <tr>

            <td>
                ${usuario.nombre}
            </td>

            <td>
                ${usuario.email}
            </td>

            <td>
                ${nombreRol(
                    usuario.rol_id_rol
                )}
            </td>


            <td>

<div class="d-flex gap-2">

    <button
        class="btn btn-soft-primary btn-sm shadow-sm"
        onclick="abrirEditar(${usuario.id_usuario})"
        title="Editar usuario">

        <i class="fas fa-pen"></i>

    </button>

    <button
        class="btn btn-soft-danger btn-sm shadow-sm"
        onclick="eliminarUsuario(${usuario.id_usuario})"
        title="Eliminar usuario">

        <i class="fas fa-trash"></i>

    </button>

</div>

            </td>

        </tr>

        `;
    });
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

    const totalUsuarios =
        document.getElementById(
            'totalUsuarios'
        );

    const totalEstudiantes =
        document.getElementById(
            'totalEstudiantes'
        );

    const totalProfesores =
        document.getElementById(
            'totalProfesores'
        );

    const totalTutores =
        document.getElementById(
            'totalTutores'
        );

    if (totalUsuarios)
        totalUsuarios.textContent =
            usuarios.length;

    if (totalEstudiantes)
        totalEstudiantes.textContent =
            estudiantes;

    if (totalProfesores)
        totalProfesores.textContent =
            profesores;

    if (totalTutores)
        totalTutores.textContent =
            tutores;
}

// =========================
// BUSCAR
// =========================

function filtrarUsuarios() {

    const texto =
        document
            .getElementById('buscar')
            .value
            .toLowerCase();

    const filtrados =
        usuarios.filter(u =>

            u.nombre
                .toLowerCase()
                .includes(texto)

            ||

            u.email
                .toLowerCase()
                .includes(texto)

        );

    renderTabla(filtrados);
}

// =========================
// CREAR USUARIO
// =========================

async function crearUsuario() {

    try {

        const nombre =
            document.getElementById(
                'nuevoNombre'
            ).value.trim();

        const usuarioEmail =
    document.getElementById(
        'nuevoEmail'
    ).value.trim();

const dominio =
    document.getElementById(
        'nuevoDominio'
    ).value;

const email =
    usuarioEmail + dominio;

        const password =
            document.getElementById(
                'nuevoPassword'
            ).value;

        const rol =
            Number(
                document.getElementById(
                    'nuevoRol'
                ).value
            );

        const res = await fetch(
            `${API}/admin/usuarios`,
            {
                method: 'POST',
                headers: {
                    'Content-Type':
                        'application/json'
                },
                body: JSON.stringify({

                    nombre,
                    email,
                    password,

                    rol_id_rol: rol,

                    es_admin:
                        rol === 1,

                    curso_id_curso:
                        null
                })
            }
        );

        if (!res.ok) {

            const error =
                await res.json();

            throw new Error(
                error.detail ||
                'Error al crear usuario'
            );
        }

        bootstrap.Modal
            .getInstance(
                document.getElementById(
                    'modalCrear'
                )
            )
            .hide();

        document.getElementById(
            'nuevoNombre'
        ).value = '';

        document.getElementById(
            'nuevoEmail'
        ).value = '';

        document.getElementById(
            'nuevoPassword'
        ).value = '';

        await cargarUsuarios();

    } catch (error) {

        console.error(error);

        alert(error.message);
    }
}

// =========================
// ABRIR EDITAR
// =========================

function abrirEditar(id) {

    const usuario =
        usuarios.find(
            u =>
                u.id_usuario === id
        );

    if (!usuario) return;

    document.getElementById(
        'editId'
    ).value =
        usuario.id_usuario;

    document.getElementById(
        'editNombre'
    ).value =
        usuario.nombre;

    document.getElementById(
        'editEmail'
    ).value =
        usuario.email;

    document.getElementById(
        'editRol'
    ).value =
        usuario.rol_id_rol;

    document.getElementById(
        'editAdmin'
    ).checked =
        usuario.es_admin;

    document.getElementById(
        'editPassword'
    ).value = '';

    new bootstrap.Modal(
        document.getElementById(
            'modalEditar'
        )
    ).show();
}

// =========================
// GUARDAR
// =========================

async function guardarUsuario() {

    try {

        const id =
            document.getElementById(
                'editId'
            ).value;

        const body = {

            nombre:
                document.getElementById(
                    'editNombre'
                ).value,

            email:
                document.getElementById(
                    'editEmail'
                ).value,

            rol_id_rol:
                Number(
                    document.getElementById(
                        'editRol'
                    ).value
                ),

            es_admin:
                document.getElementById(
                    'editAdmin'
                ).checked
        };

        const password =
            document.getElementById(
                'editPassword'
            ).value;

        if (password) {

            body.password =
                password;
        }

        const res = await fetch(
            `${API}/admin/usuarios/${id}`,
            {
                method: 'PATCH',
                headers: {
                    'Content-Type':
                        'application/json'
                },
                body:
                    JSON.stringify(body)
            }
        );

        if (!res.ok) {

            throw new Error(
                'Error actualizando usuario'
            );
        }

        bootstrap.Modal
            .getInstance(
                document.getElementById(
                    'modalEditar'
                )
            )
            .hide();

        await cargarUsuarios();

    } catch (error) {

        console.error(error);

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
        '¿Eliminar usuario?'
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

            throw new Error(
                'Error eliminando usuario'
            );
        }

        await cargarUsuarios();

    } catch (error) {

        console.error(error);

        alert(
            'No fue posible eliminar el usuario'
        );
    }
}

// =========================
// INICIO
// =========================

document.addEventListener(
    'DOMContentLoaded',
    () => {

        cargarUsuarios();

        const dominio =
            document.getElementById(
                "nuevoDominio"
            );

        const rol =
            document.getElementById(
                "nuevoRol"
            );

        if(dominio){

            dominio.addEventListener(
                "change",
                actualizarDominio
            );
        }

        if(rol){

            rol.addEventListener(
                "change",
                sincronizarDominioRol
            );
        }

        actualizarDominio();
        sincronizarDominioRol();

    }
);

function sincronizarDominioRol(){

    const rol =
        document.getElementById(
            "nuevoRol"
        ).value;

    const dominio =
        document.getElementById(
            "nuevoDominio"
        );

    switch(Number(rol)){

        case 1:
            dominio.value =
                "@admin.com";
            break;

        case 2:
            dominio.value =
                "@profesor.com";
            break;

        case 3:
            dominio.value =
                "@tutor.com";
            break;

        case 4:
            dominio.value =
                "@estudiante.com";
            break;
    }

    actualizarDominio();
}