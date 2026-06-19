let estudiantes = [];

const API = "https://anticipa.onrender.com";

document.addEventListener("DOMContentLoaded", () => {
    cargarEstudiantes();
    initFiltros();
});

// =======================================
// CARGAR ESTUDIANTES
// =======================================
async function cargarEstudiantes() {

    try {

        const res = await fetch(`${API}/estudiantes/`);

        if (!res.ok) {
            throw new Error("Error cargando estudiantes");
        }

        estudiantes = await res.json();

        console.log("ESTUDIANTES CARGADOS:", estudiantes);

        cargarCursos();
        cargarTabla(estudiantes);
        cargarMetricas();
        cargarGraficos();

    } catch (error) {
        console.error(error);
        alert("No se pudieron cargar los estudiantes desde el backend");
    }
}

// =======================================
// MÉTRICAS (TARJETAS)
// =======================================
function cargarMetricas() {

    const totalEstudiantes = document.getElementById("totalEstudiantes");
    const totalTEA = document.getElementById("totalTEA");
    const totalTDAH = document.getElementById("totalTDAH");
    const totalRiesgo = document.getElementById("totalRiesgo");

    if (totalEstudiantes) {
        totalEstudiantes.textContent = estudiantes.length;
    }

    if (totalTEA) {
        totalTEA.textContent = estudiantes.filter(x =>
            (x.diagnostico || "").trim().toUpperCase() === "TEA"
        ).length;
    }

    if (totalTDAH) {
        totalTDAH.textContent = estudiantes.filter(x =>
            (x.diagnostico || "").trim().toUpperCase() === "TDAH"
        ).length;
    }

    if (totalRiesgo) {
        totalRiesgo.textContent = estudiantes.filter(x =>
            (x.estado || "").trim().toUpperCase() === "RIESGO"
        ).length;
    }
}

// =======================================
// TABLA
// =======================================
function cargarTabla(lista) {

    const tabla = document.getElementById("tablaEstudiantes");
    tabla.innerHTML = "";

    lista.forEach(e => {

        tabla.innerHTML += `
        <tr>
            <td>${e.nombre}</td>
            <td>${e.curso_r?.nivel_academico || ""}${e.curso_r?.letra_academica || ""}</td>
            <td>${e.diagnostico}</td>
            <td>${e.puntos_totales || 0}</td>
            <td>
                <span class="badge ${
                    e.estado === "Riesgo"
                        ? "bg-danger"
                        : e.estado === "Estable"
                            ? "bg-warning text-dark"
                            : "bg-success"
                }">
                    ${e.estado}
                </span>
            </td>
            <td>
                <button class="btn btn-primary btn-sm"
                    onclick="verEstudiante(${e.id_estudiante})">
                    Ver
                </button>
            </td>
        </tr>
        `;
    });
}

// =======================================
// FILTROS
// =======================================
function cargarCursos() {

    const select = document.getElementById("filtroCurso");

    if (!select) return;

    select.innerHTML = `<option value="">Todos los cursos</option>`;

    const cursos = [
        ...new Set(
            estudiantes
                .map(e =>
                    e.curso_r
                        ? `${e.curso_r.nivel_academico}${e.curso_r.letra_academica}`
                        : null
                )
                .filter(Boolean)
        )
    ].sort();

    cursos.forEach(curso => {
        select.innerHTML += `<option value="${curso}">${curso}</option>`;
    });
}

function aplicarFiltros() {

    const texto = document.getElementById("buscar").value.toLowerCase();
    const curso = document.getElementById("filtroCurso").value;
    const diagnostico = document.getElementById("filtroDiagnostico").value;
    const estado = document.getElementById("filtroEstado").value;
    const orden = document.getElementById("ordenarPor").value;

    let resultado = [...estudiantes];

    resultado = resultado.filter(e => {

        const nombre = (e.nombre || "").toLowerCase();

        const cursoNombre =
            e.curso_r
                ? `${e.curso_r.nivel_academico}${e.curso_r.letra_academica}`
                : "";

        return (
            nombre.includes(texto) &&
            (curso === "" || cursoNombre === curso) &&
            (diagnostico === "" || e.diagnostico === diagnostico) &&
            (estado === "" || e.estado === estado)
        );
    });

    switch (orden) {
        case "totalDesc":
            resultado.sort((a, b) => (b.puntos_totales || 0) - (a.puntos_totales || 0));
            break;

        case "totalAsc":
            resultado.sort((a, b) => (a.puntos_totales || 0) - (b.puntos_totales || 0));
            break;
    }

    cargarTabla(resultado);
}

// =======================================
// INICIALIZAR FILTROS
// =======================================
function initFiltros() {

    document.getElementById("buscar")?.addEventListener("input", aplicarFiltros);
    document.getElementById("filtroCurso")?.addEventListener("change", aplicarFiltros);
    document.getElementById("filtroDiagnostico")?.addEventListener("change", aplicarFiltros);
    document.getElementById("filtroEstado")?.addEventListener("change", aplicarFiltros);
    document.getElementById("ordenarPor")?.addEventListener("change", aplicarFiltros);
}

// =======================================
// GRAFICOS
// =======================================
function cargarGraficos() {

    const cursos = {};

    estudiantes.forEach(est => {

        const curso = est.curso_r
            ? `${est.curso_r.nivel_academico}${est.curso_r.letra_academica}`
            : "";

        if (!curso) return;

        cursos[curso] =
            (cursos[curso] || 0) + (est.puntos_totales || 0);
    });

    const labels = Object.keys(cursos);
    const valores = Object.values(cursos);

    const grafCursos = document.getElementById("graficoCursos");

    if (grafCursos) {

        new Chart(grafCursos, {
            type: "bar",
            data: {
                labels,
                datasets: [{
                    label: "Desregulaciones",
                    data: valores
                }]
            }
        });
    }

    const riesgo = estudiantes.filter(e =>
        (e.estado || "").toUpperCase() === "RIESGO"
    ).length;

    const estable = estudiantes.filter(e =>
        (e.estado || "").toUpperCase() === "ESTABLE"
    ).length;

    const mejorando = estudiantes.filter(e =>
        (e.estado || "").toUpperCase() === "MEJORANDO"
    ).length;

    const grafTendencia = document.getElementById("graficoTendencia");

    if (grafTendencia) {

        new Chart(grafTendencia, {
            type: "doughnut",
            data: {
                labels: ["Riesgo", "Estable", "Mejorando"],
                datasets: [{
                    data: [riesgo, estable, mejorando]
                }]
            }
        });
    }
}