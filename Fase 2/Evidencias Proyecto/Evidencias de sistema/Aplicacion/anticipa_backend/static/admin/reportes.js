document.addEventListener("DOMContentLoaded", async () => {

    const API = "https://anticipa.onrender.com";

    let datosReporte = null;

    try {

        const response = await fetch(`${API}/reportes/dashboard`);

        if (!response.ok) {
            throw new Error("Sin datos");
        }

        datosReporte = await response.json();

    } catch (error) {

        console.error("Error cargando dashboard:", error);

        alert("No se pudieron cargar los datos del reporte");

        return;
    }

    // =========================
    // KPI
    // =========================

    document.getElementById("mejoraGlobal").textContent =
        datosReporte.mejoraGlobal ?? "0";

    document.getElementById("riesgoAlto").textContent =
        datosReporte.riesgoAlto ?? 0;

    document.getElementById("factorPrincipal").textContent =
        datosReporte.factorPrincipal ?? "-";

    document.getElementById("cursoCritico").textContent =
        datosReporte.cursoCritico ?? "-";


    // =========================
    // EVOLUCIÓN
    // =========================

    new Chart(
        document.getElementById("graficoEvolucion"),
        {
            type: "line",
            data: {
                labels: datosReporte.evolucion?.labels || [],
                datasets: [{
                    label: "Desregulaciones",
                    data: datosReporte.evolucion?.data || [],
                    borderWidth: 3,
                    tension: 0.4
                }]
            }
        }
    );


    // =========================
    // FACTORES
    // =========================

    new Chart(
        document.getElementById("graficoFactores"),
        {
            type: "pie",
            data: {
                labels: datosReporte.factores?.labels || [],
                datasets: [{
                    data: datosReporte.factores?.data || []
                }]
            }
        }
    );


    // =========================
    // DÍAS
    // =========================

    new Chart(
        document.getElementById("graficoDias"),
        {
            type: "bar",
            data: {
                labels: datosReporte.dias?.labels || [],
                datasets: [{
                    label: "Eventos",
                    data: datosReporte.dias?.data || []
                }]
            }
        }
    );


    // =========================
    // CURSOS
    // =========================

    new Chart(
        document.getElementById("graficoCursos"),
        {
            type: "bar",
            data: {
                labels: datosReporte.cursos?.labels || [],
                datasets: [{
                    label: "Incidentes",
                    data: datosReporte.cursos?.data || []
                }]
            }
        }
    );


    // =========================
    // HALLAZGOS
    // =========================

    const lista = document.getElementById("insights");

    if (lista) {

        lista.innerHTML = "";

        (datosReporte.hallazgos || []).forEach(texto => {

            lista.innerHTML += `
                <li class="list-group-item">
                    📊 ${texto}
                </li>
            `;
        });
    }


    // =========================
    // PDF GENERAL
    // =========================

    const btnPdf = document.getElementById("btnPdf");

    if (btnPdf) {

        btnPdf.addEventListener("click", () => {

            window.open(`${API}/reportes/pdf-general`, "_blank");

        });
    }


    // =========================
    // EXCEL
    // =========================

    const btnExcel = document.getElementById("btnExcel");

    if (btnExcel) {

        btnExcel.addEventListener("click", () => {

            alert("Excel aún no conectado al backend");

        });
    }

});