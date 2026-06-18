function cargarSidebar() {

    const pagina =
        window.location.pathname
            .split("/")
            .pop();

    let menu = `
    
    <aside class="sidebar">

        <div class="sidebar-header">
            <h3>🧩 Anticipa</h3>
            <span>Colegio Sagrado Corazón</span>
        </div>

        <ul class="sidebar-menu">


            <li class="${pagina === 'usuarios.html' ? 'active' : ''}">
                <a href="usuarios.html">
                    <i class="bi bi-people-fill"></i>
                    Usuarios
                </a>
            </li>

            <li class="${pagina === 'estudiantes.html' ? 'active' : ''}">
                <a href="estudiantes.html">
                    <i class="bi bi-mortarboard-fill"></i>
                    Estudiantes
                </a>
            </li>

            <li class="${pagina === 'reportes.html' ? 'active' : ''}">
                <a href="reportes.html">
                    <i class="bi bi-bar-chart-fill"></i>
                    Reportes
                </a>
            </li>

        </ul>

        <div class="sidebar-footer">

            <button
                class="btn btn-danger w-100"
                onclick="logout()">

                <i class="bi bi-box-arrow-right"></i>
                Cerrar Sesión

            </button>

        </div>

    </aside>
    `;

    document.getElementById("sidebarContainer").innerHTML =
        menu;
}

document.addEventListener(
    "DOMContentLoaded",
    cargarSidebar
);