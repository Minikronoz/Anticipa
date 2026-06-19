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
    const totalRiesgo = document.getElementById("totalRiesgo");

    if (totalEstudiantes) {
        totalEstudiantes.textContent = estudiantes.length;
    }

    // Agrupar diagnósticos dinámicamente
    const diagnosticos = {};

    estudiantes.forEach(x => {
        const diag = (x.diagnostico || "SIN DIAGNOSTICO").trim().toUpperCase();
        diagnosticos[diag] = (diagnosticos[diag] || 0) + 1;
    });

    // Render automático en el HTML
    Object.keys(diagnosticos).forEach(diag => {
        const el = document.getElementById(`total${diag}`);

        if (el) {
            el.textContent = diagnosticos[diag];
        }
    });

    // Riesgo separado (estado)
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

function cargarGraficos() {

    if (!estudiantes.length) return;

    // ===================================
    // GRÁFICO POR CURSOS (PUNTOS)
    // ===================================
    const cursos = {};

    estudiantes.forEach(est => {

        const curso = est.curso_r
            ? `${est.curso_r.nivel_academico}${est.curso_r.letra_academica}`
            : "";

        if (!curso) return;

        cursos[curso] = (cursos[curso] || 0) + (est.puntos_totales || 0);
    });

    const labelsCursos = Object.keys(cursos);
    const valoresCursos = Object.values(cursos);

    const grafCursos = document.getElementById("graficoCursos");

    if (grafCursos) {

        if (window.graficoCursosInstance) {
            window.graficoCursosInstance.destroy();
        }

        window.graficoCursosInstance = new Chart(grafCursos, {
            type: "bar",
            data: {
                labels: labelsCursos,
                datasets: [{
                    label: "Desregulaciones por curso",
                    data: valoresCursos
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    x: {
                        title: {
                            display: true,
                            text: "Cursos"
                        }
                    },
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: "Cantidad de desregulaciones"
                        }
                    }
                }
            }
        });
    }

    // ===================================
    // GRÁFICO DE ESTADOS (OPTIMIZADO)
    // ===================================

    let riesgo = 0;
    let estable = 0;
    let mejorando = 0;

    estudiantes.forEach(e => {

        const estado = (e.estado || "").toUpperCase();

        if (estado === "RIESGO") riesgo++;
        else if (estado === "ESTABLE") estable++;
        else if (estado === "MEJORANDO") mejorando++;
    });

    const grafTendencia = document.getElementById("graficoTendencia");

    if (grafTendencia) {

        if (window.graficoTendenciaInstance) {
            window.graficoTendenciaInstance.destroy();
        }

        window.graficoTendenciaInstance = new Chart(grafTendencia, {
            type: "doughnut",
            data: {
                labels: ["Riesgo", "Estable", "Mejorando"],
                datasets: [{
                    data: [riesgo, estable, mejorando],
                    backgroundColor: [
                        "#e74c3c",
                        "#f1c40f",
                        "#2ecc71"
                    ],
                    borderWidth: 1
                }]
            }
        });
    }
}


function verEstudiante(id) {

    const estudiante = estudiantes.find(
        e => Number(e.id_estudiante) === Number(id)
    );

    if (!estudiante) return;

    // =========================
    // TÍTULO
    // =========================
    document.getElementById("tituloEstudiante").textContent =
        estudiante.nombre || "Sin nombre";

    // =========================
    // CURSO
    // =========================
    const curso = document.getElementById("datoCurso");
    if (curso) {
        const c = estudiante.curso_r
            ? `${estudiante.curso_r.nivel_academico}${estudiante.curso_r.letra_academica}`
            : "SIN CURSO";

        curso.textContent = c;
    }

    // =========================
    // DIAGNÓSTICO
    // =========================
    document.getElementById("datoDiagnostico").textContent =
        (estudiante.diagnostico || "SIN DIAGNÓSTICO").toUpperCase();

    // =========================
    // ESTADO
    // =========================
    document.getElementById("datoEstado").textContent =
        (estudiante.estado || "SIN ESTADO").toUpperCase();

    // =========================
    // PUNTOS (ÚNICO MÉTRICO REAL DEL ESTUDIANTE)
    // =========================
    const puntos = estudiante.puntos_totales || 0;

    const puntosUI = document.getElementById("datoPuntos");
    if (puntosUI) {
        puntosUI.textContent = puntos;
    }

    // =========================
    // MODAL
    // =========================
    new bootstrap.Modal(
        document.getElementById("modalEstudiante")
    ).show();
}