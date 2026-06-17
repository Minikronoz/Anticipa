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
            <td>${e.semana || 0}</td>
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

        const cursoNombre = (e.curso_r?.nivel_academico || "") +
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
            resultado.sort((a, b) => b.puntos_totales - a.puntos_totales);
            break;

        case "totalAsc":
            resultado.sort((a, b) => a.puntos_totales - b.puntos_totales);
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

});


