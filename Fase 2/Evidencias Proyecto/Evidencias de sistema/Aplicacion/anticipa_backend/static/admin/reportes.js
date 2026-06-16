document.addEventListener("DOMContentLoaded", async () => {

let datosReporte;

try{

// FUTURO ENDPOINT FASTAPI
const response = await fetch("http://localhost:8000/admin/reportes");

if(!response.ok){
throw new Error("Sin datos");
}

datosReporte = await response.json();

}catch(error){

console.log("Usando datos de prueba");

// DATOS FICTICIOS
datosReporte = {

mejoraGlobal:"37%",
riesgoAlto:4,
factorPrincipal:"Conflictos Familiares",
cursoCritico:"5°A",

evolucion:{
labels:["Ene","Feb","Mar","Abr","May","Jun"],
data:[120,110,98,85,72,64]
},

factores:{
labels:[
"Conflictos Familiares",
"Ruido",
"Cambios Rutina",
"Comidas",
"Evaluaciones"
],
data:[35,20,18,15,12]
},

dias:{
labels:["Lun","Mar","Mié","Jue","Vie"],
data:[25,30,18,35,14]
},

cursos:{
labels:["1°A","2°A","3°A","4°A","5°A"],
data:[8,12,18,10,25]
},

hallazgos:[

"Las desregulaciones disminuyeron un 37% desde la implementación de Anticipa.",

"Los conflictos familiares representan el principal desencadenante.",

"Los jueves presentan la mayor cantidad de incidentes.",

"El curso 5°A requiere intervención prioritaria.",

"Los estudiantes TEA presentan una reducción promedio del 42% en incidentes.",

"El 68% de las desregulaciones ocurre antes del almuerzo.",

"Las alertas tempranas permitieron evitar 23 posibles crisis durante el último mes."

]

};

}

// KPI

document.getElementById("mejoraGlobal").textContent =
datosReporte.mejoraGlobal;

document.getElementById("riesgoAlto").textContent =
datosReporte.riesgoAlto;

document.getElementById("factorPrincipal").textContent =
datosReporte.factorPrincipal;

document.getElementById("cursoCritico").textContent =
datosReporte.cursoCritico;


// EVOLUCION

new Chart(
document.getElementById("graficoEvolucion"),
{
type:"line",
data:{
labels:datosReporte.evolucion.labels,
datasets:[{
label:"Desregulaciones",
data:datosReporte.evolucion.data,
borderWidth:3,
tension:.4
}]
}
}
);


// FACTORES

new Chart(
document.getElementById("graficoFactores"),
{
type:"pie",
data:{
labels:datosReporte.factores.labels,
datasets:[{
data:datosReporte.factores.data
}]
}
}
);


// DIAS

new Chart(
document.getElementById("graficoDias"),
{
type:"bar",
data:{
labels:datosReporte.dias.labels,
datasets:[{
label:"Eventos",
data:datosReporte.dias.data
}]
}
}
);


// CURSOS

new Chart(
document.getElementById("graficoCursos"),
{
type:"bar",
data:{
labels:datosReporte.cursos.labels,
datasets:[{
label:"Incidentes",
data:datosReporte.cursos.data
}]
}
}
);


// HALLAZGOS

const lista = document.getElementById("insights");

lista.innerHTML = "";

datosReporte.hallazgos.forEach(texto=>{

lista.innerHTML += `
<li class="list-group-item">
📊 ${texto}
</li>
`;

});

});