const desregulaciones = [

    {
        id: 1,
        estudiante: "Sebastián Solar",
        curso: "4°A",
        tipo: "Conductual",
        fecha: "2026-06-12",
        estado: "Pendiente"
    },

    {
        id: 2,
        estudiante: "María González",
        curso: "3°B",
        tipo: "Académica",
        fecha: "2026-06-10",
        estado: "Resuelta"
    },

    {
        id: 3,
        estudiante: "Juan Pérez",
        curso: "2°A",
        tipo: "Asistencia",
        fecha: "2026-06-09",
        estado: "Pendiente"
    }

];

// =========================
// para activar 
// const response = await fetch(API_URL + "/desregulaciones");
// const desregulaciones = await response.json();
// =========================



function cargarDesregulaciones() {

    const tabla = document.getElementById("tablaDesregulaciones");

    tabla.innerHTML = "";

    desregulaciones.forEach(d => {

        tabla.innerHTML += `

        <tr>

            <td>${d.estudiante}</td>

            <td>${d.curso}</td>

            <td>${d.tipo}</td>

            <td>${d.fecha}</td>

            <td>
                <span class="badge ${d.estado === 'Pendiente'
                    ? 'bg-warning'
                    : 'bg-success'}">

                    ${d.estado}

                </span>
            </td>

            <td>

                <button class="btn btn-sm btn-primary">

                    <i class="bi bi-eye"></i>

                </button>

            </td>

        </tr>

        `;
    });

    actualizarMetricas();
}

function actualizarMetricas() {

    document.getElementById("totalAlertas").textContent =
        desregulaciones.length;

    document.getElementById("pendientes").textContent =
        desregulaciones.filter(x => x.estado === "Pendiente").length;

    document.getElementById("resueltas").textContent =
        desregulaciones.filter(x => x.estado === "Resuelta").length;

    document.getElementById("estudiantesRiesgo").textContent = 2;
}

document.addEventListener("DOMContentLoaded", () => {

    cargarDesregulaciones();

});