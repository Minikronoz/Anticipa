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

        btnPdf.addEventListener("click", async () => {

            const { jsPDF } = window.jspdf;
            const pdf = new jsPDF("p", "mm", "a4");
            const pageWidth = pdf.internal.pageSize.getWidth();
            const pageHeight = pdf.internal.pageSize.getHeight();
            const margin = 15;
            let yPos = margin;

            pdf.setFontSize(20);
            pdf.setTextColor(31, 78, 121);
            pdf.text("ANTICIPA - Reporte General", margin, yPos);
            yPos += 10;

            pdf.setFontSize(10);
            pdf.setTextColor(100);
            const fechaChile = new Date().toLocaleString("es-CL", { timeZone: "America/Santiago" });
            pdf.text(`Generado: ${fechaChile}`, margin, yPos);
            yPos += 15;

            pdf.setFontSize(14);
            pdf.setTextColor(0);
            pdf.text("Resumen Ejecutivo", margin, yPos);
            yPos += 8;

            pdf.setFontSize(10);
            pdf.setTextColor(60);
            const resumenTexto = `
Plataforma de seguimiento para estudiantes con Necesidades Educativas Especiales.
Este reporte presenta metricas de desregulacion emocional y seguimiento de progreso.
            `.trim();
            const lineasResumen = pdf.splitTextToSize(resumenTexto, pageWidth - 2 * margin);
            pdf.text(lineasResumen, margin, yPos);
            yPos += lineasResumen.length * 5 + 10;

            pdf.setFontSize(12);
            pdf.setTextColor(0);
            pdf.text("Indicadores Clave", margin, yPos);
            yPos += 8;

            const kpiData = [
                ["Indicador", "Valor"],
                ["Mejora Global", datosReporte.mejoraGlobal || "0%"],
                ["Riesgo Alto", String(datosReporte.riesgoAlto || 0)],
                ["Factor Principal", datosReporte.factorPrincipal || "-"],
                ["Curso Critico", datosReporte.cursoCritico || "-"]
            ];

            pdf.setFontSize(9);
            kpiData.forEach((fila, i) => {
                if (i === 0) {
                    pdf.setFillColor(31, 78, 121);
                    pdf.setTextColor(255);
                } else if (i % 2 === 0) {
                    pdf.setFillColor(240, 240, 240);
                    pdf.setTextColor(0);
                } else {
                    pdf.setFillColor(255, 255, 255);
                    pdf.setTextColor(0);
                }
                pdf.rect(margin, yPos - 4, pageWidth - 2 * margin, 7, "FD");
                pdf.text(fila[0], margin + 2, yPos);
                pdf.text(fila[1], margin + 80, yPos);
                yPos += 7;
            });

            yPos += 10;

            pdf.setFontSize(12);
            pdf.setTextColor(0);
            pdf.text("Captura del Dashboard", margin, yPos);
            yPos += 5;

            try {
                const elementoReportes = document.querySelector(".main-content");
                if (elementoReportes) {
                    const canvas = await html2canvas(elementoReportes, {
                        scale: 2,
                        useCORS: true,
                        allowTaint: true,
                        backgroundColor: "#ffffff"
                    });
                    const imgData = canvas.toDataURL("image/png");
                    const imgWidth = pageWidth - 2 * margin;
                    const imgHeight = (canvas.height * imgWidth) / canvas.width;
                    if (yPos + imgHeight > pageHeight - margin) {
                        pdf.addPage();
                        yPos = margin;
                    }
                    pdf.addImage(imgData, "PNG", margin, yPos, imgWidth, Math.min(imgHeight, pageHeight - yPos - margin));
                    yPos += imgHeight + 10;
                }
            } catch (e) {
                console.warn("No se pudo capturar el dashboard:", e);
            }

            if (yPos > pageHeight - 60) {
                pdf.addPage();
                yPos = margin;
            }

            pdf.setFontSize(12);
            pdf.text("Datos Detallados", margin, yPos);
            yPos += 8;

            pdf.setFontSize(10);
            pdf.text("Evolucion de Desregulaciones (ultimos 6 meses):", margin, yPos);
            yPos += 6;
            const evoLabels = datosReporte.evolucion?.labels || [];
            const evoData = datosReporte.evolucion?.data || [];
            const evoTotal = evoData.reduce((a, b) => a + b, 0) || 1;
            evoLabels.forEach((label, i) => {
                const valor = evoData[i] || 0;
                const pct = ((valor / evoTotal) * 100).toFixed(1);
                pdf.text(`${label}: ${valor} episodios (${pct}%)`, margin + 5, yPos);
                yPos += 5;
            });

            yPos += 5;
            pdf.text("Factores Desencadenantes:", margin, yPos);
            yPos += 6;
            const facLabels = datosReporte.factores?.labels || [];
            const facData = datosReporte.factores?.data || [];
            const facTotal = facData.reduce((a, b) => a + b, 0) || 1;
            facLabels.forEach((label, i) => {
                const valor = facData[i] || 0;
                const pct = ((valor / facTotal) * 100).toFixed(1);
                pdf.text(`${label}: ${valor} (${pct}%)`, margin + 5, yPos);
                yPos += 5;
            });

            yPos += 5;
            pdf.text("Desregulaciones por Dia:", margin, yPos);
            yPos += 6;
            const diasLabels = datosReporte.dias?.labels || [];
            const diasData = datosReporte.dias?.data || [];
            const diasTotal = diasData.reduce((a, b) => a + b, 0) || 1;
            diasLabels.forEach((label, i) => {
                const valor = diasData[i] || 0;
                const pct = ((valor / diasTotal) * 100).toFixed(1);
                pdf.text(`${label}: ${valor} (${pct}%)`, margin + 5, yPos);
                yPos += 5;
            });

            yPos += 5;
            pdf.text("Comparacion por Curso:", margin, yPos);
            yPos += 6;
            const cursLabels = datosReporte.cursos?.labels || [];
            const cursData = datosReporte.cursos?.data || [];
            const cursTotal = cursData.reduce((a, b) => a + b, 0) || 1;
            cursLabels.forEach((label, i) => {
                const valor = cursData[i] || 0;
                const pct = ((valor / cursTotal) * 100).toFixed(1);
                pdf.text(`${label}: ${valor} (${pct}%)`, margin + 5, yPos);
                yPos += 5;
            });

            if (yPos > pageHeight - 30) {
                pdf.addPage();
                yPos = margin;
            }

            yPos += 5;
            pdf.setFontSize(12);
            pdf.text("Hallazgos", margin, yPos);
            yPos += 8;
            pdf.setFontSize(9);
            const hallazgos = datosReporte.hallazgos || [];
            hallazgos.forEach((h, i) => {
                const lines = pdf.splitTextToSize(`${i + 1}. ${h}`, pageWidth - 2 * margin);
                pdf.text(lines, margin, yPos);
                yPos += lines.length * 4 + 2;
            });

            yPos = pageHeight - 15;
            pdf.setFontSize(8);
            pdf.setTextColor(150);
            pdf.text("Documento generado automaticamente por Anticipa.", margin, yPos);

            const fecha = new Date().toISOString().slice(0, 10);
            pdf.save(`Reporte_Anticipa_${fecha}.pdf`);

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