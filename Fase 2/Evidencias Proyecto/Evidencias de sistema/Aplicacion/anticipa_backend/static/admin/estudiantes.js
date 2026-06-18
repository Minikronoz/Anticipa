let estudiantes = [];
let historial = {};

let graficoAlumno = null;
let graficoImpacto = null;
const API = "https://anticipa.onrender.com";
// =======================================
// CARGAR ESTUDIANTES DESDE BACKEND
// =======================================
async function cargarEstudiantes() {

    try {

        const res = await fetch(`${API}/estudiantes/`)

        if (!res.ok) {
            throw new Error("Error cargando estudiantes");
        }

        estudiantes = await res.json();

        cargarCursos();
        cargarTabla(estudiantes);

        document.getElementById("totalEstudiantes").textContent = estudiantes.length;

        document.getElementById("totalTEA").textContent =
            estudiantes.filter(x => x.diagnostico === "TEA").length;

        document.getElementById("totalTDAH").textContent =
            estudiantes.filter(x => x.diagnostico === "TDAH").length;

        document.getElementById("totalRiesgo").textContent =
            estudiantes.filter(x => x.estado === "Riesgo").length;

    } catch (error) {

        console.error("Error:", error);

        alert("No se pudieron cargar los estudiantes desde el backend");

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

    const cursos = [
    ...new Set(
        estudiantes
            .map(e => {
                if (!e.curso_r) return null;
                return `${e.curso_r.nivel_academico}${e.curso_r.letra_academica}`;
            })
            .filter(Boolean)
    )
].sort();

    cursos.forEach(curso => {

        select.innerHTML += `
        <option value="${curso}">
            ${curso}
        </option>
        `;

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

        const nombre = e.nombre.toLowerCase();

        const cursoNombre =
            (e.curso_r?.nivel_academico || "") +
            (e.curso_r?.letra_academica || "");

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
// VER ESTUDIANTE (MODAL)
// =======================================
function verEstudiante(id) {

    fetch(`${API}/reportes/detalle-estudiante/${id}`)
        .then(res => res.json())
        .then(datos => {

            document.getElementById("tituloEstudiante").innerHTML =
                `${datos.nombre} - ${datos.curso}`;

            document.getElementById("datoHoy").innerHTML = datos.hoy;
            document.getElementById("datoSemana").innerHTML = datos.semana;
            document.getElementById("datoMes").innerHTML = datos.mes;

            if (graficoAlumno) graficoAlumno.destroy();
            if (graficoImpacto) graficoImpacto.destroy();

            graficoAlumno = new Chart(
                document.getElementById("graficoAlumno"),
                {
                    type: "line",
                    data: {
                        labels: ["Ene", "Feb", "Mar", "Abr", "May", "Jun"],
                        datasets: [{
                            label: "Desregulaciones",
                            data: datos.historial,
                            borderWidth: 3,
                            tension: 0.3
                        }]
                    }
                }
            );

            graficoImpacto = new Chart(
                document.getElementById("graficoImpacto"),
                {
                    type: "bar",
                    data: {
                        labels: ["Antes", "Actual"],
                        datasets: [{
                            label: "Incidentes",
                            data: [
                                datos.historial[0],
                                datos.historial[5]
                            ]
                        }]
                    }
                }
            );

            const inicio = datos.historial[0] || 0;
const fin = datos.historial[datos.historial.length - 1] || 0;

let cambio = Math.round(((fin - inicio) / (inicio || 1)) * 100);

            document.getElementById("observacion").innerHTML =
                cambio < 0
                    ? `El estudiante ha mejorado un ${Math.abs(cambio)}%`
                    : `Se detecta aumento del ${cambio}%`;

            new bootstrap.Modal(
                document.getElementById("modalEstudiante")
            ).show();

        });
}

// =======================================
// INIT
// =======================================
document.addEventListener("DOMContentLoaded", async () => {

    await cargarEstudiantes();

    document.getElementById("buscar").addEventListener("input", aplicarFiltros);
    document.getElementById("filtroCurso").addEventListener("change", aplicarFiltros);
    document.getElementById("filtroDiagnostico").addEventListener("change", aplicarFiltros);
    document.getElementById("filtroEstado").addEventListener("change", aplicarFiltros);
    document.getElementById("ordenarPor").addEventListener("change", aplicarFiltros);

    // Gráficos de la página principal
    if (typeof Chart !== "undefined") {
        // Gráfico Desregulaciones por Curso
        const grafCursos = document.getElementById("graficoCursos");
        if (grafCursos) {
            new Chart(grafCursos, {
                type: "bar",
                data: {
                    labels: ["1°A", "2°A", "3°A", "4°A", "5°A"],
                    datasets: [{
                        label: "Incidentes",
                        data: [8, 12, 18, 10, 25],
                        backgroundColor: ["#1565C0", "#43A047", "#FB8C00", "#8E24AA", "#E53935"]
                    }]
                },
                options: {
                    responsive: true,
                    plugins: { legend: { display: false } },
                    scales: { y: { beginAtZero: true } }
                }
            });
        }

        // Gráfico Tendencia General
        const grafTendencia = document.getElementById("graficoTendencia");
        if (grafTendencia) {
            new Chart(grafTendencia, {
                type: "line",
                data: {
                    labels: ["Ene", "Feb", "Mar", "Abr", "May", "Jun"],
                    datasets: [{
                        label: "Desregulaciones",
                        data: [120, 110, 98, 85, 72, 64],
                        borderColor: "#E53935",
                        backgroundColor: "rgba(229, 57, 53, 0.1)",
                        fill: true,
                        tension: 0.4,
                        borderWidth: 3
                    }]
                },
                options: {
                    responsive: true,
                    plugins: { legend: { position: "bottom" } },
                    scales: { y: { beginAtZero: true } }
                }
            });
        }
    }

});


