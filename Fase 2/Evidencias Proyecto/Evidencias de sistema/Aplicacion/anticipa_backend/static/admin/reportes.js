document.addEventListener("DOMContentLoaded",()=>{

document.getElementById("mejoraGlobal").innerHTML="37%";
document.getElementById("riesgoAlto").innerHTML="4";
document.getElementById("factorPrincipal").innerHTML="Conflictos";
document.getElementById("cursoCritico").innerHTML="5°A";

new Chart(
document.getElementById("graficoEvolucion"),
{
type:"line",
data:{
labels:["Ene","Feb","Mar","Abr","May","Jun"],
datasets:[{
label:"Desregulaciones",
data:[120,110,98,85,72,64],
borderWidth:3,
tension:.3
}]
}
});

new Chart(
document.getElementById("graficoFactores"),
{
type:"pie",
data:{
labels:[
"Conflictos Familiares",
"Ruido",
"Comidas",
"Cambios Rutina",
"Evaluaciones"
],
datasets:[{
data:[35,20,15,18,12]
}]
}
});

new Chart(
document.getElementById("graficoDias"),
{
type:"bar",
data:{
labels:[
"Lun",
"Mar",
"Mié",
"Jue",
"Vie"
],
datasets:[{
label:"Eventos",
data:[25,30,18,35,14]
}]
}
});

new Chart(
document.getElementById("graficoCursos"),
{
type:"bar",
data:{
labels:[
"1°A",
"2°A",
"3°A",
"4°A",
"5°A"
],
datasets:[{
label:"Incidentes",
data:[8,12,18,10,25]
}]
}
});

const hallazgos = [

"Las desregulaciones disminuyeron un 37% desde la implementación de Anticipa.",

"Los conflictos familiares representan el principal desencadenante.",

"Los jueves presentan la mayor cantidad de incidentes.",

"El curso 5°A requiere intervención prioritaria.",

"Los estudiantes TEA presentan una reducción promedio del 42% en incidentes.",

"El 68% de las desregulaciones ocurre antes del almuerzo.",

"Los días con menú que incluye frutas ácidas muestran un aumento del 12% en algunos estudiantes sensibles.",

"Las alertas tempranas permitieron evitar 23 posibles crisis durante el último mes."

];

const lista=document.getElementById("insights");

hallazgos.forEach(texto=>{

lista.innerHTML += `
<li class="list-group-item">
📊 ${texto}
</li>
`;

});

});