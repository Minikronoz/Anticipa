const estudiantes = [

{
id:1,
nombre:"Juan Pérez",
curso:"5°A",
diagnostico:"TEA",
total:12,
semana:1,
estado:"Mejorando"
},
{
id:2,
nombre:"María Soto",
curso:"5°A",
diagnostico:"TDAH",
total:18,
semana:2,
estado:"Estable"
},
{
id:3,
nombre:"Diego Muñoz",
curso:"5°A",
diagnostico:"TEA",
total:5,
semana:0,
estado:"Mejorando"
},
{
id:4,
nombre:"Fernanda Díaz",
curso:"5°B",
diagnostico:"TDAH",
total:22,
semana:4,
estado:"Riesgo"
},
{
id:5,
nombre:"Catalina Torres",
curso:"5°B",
diagnostico:"TEA",
total:7,
semana:1,
estado:"Mejorando"
},
{
id:6,
nombre:"Matías Rojas",
curso:"5°B",
diagnostico:"TEL",
total:10,
semana:1,
estado:"Estable"
},
{
id:7,
nombre:"Benjamín Silva",
curso:"6°A",
diagnostico:"TEA",
total:15,
semana:3,
estado:"Estable"
},
{
id:8,
nombre:"Josefa Morales",
curso:"6°A",
diagnostico:"TDAH",
total:9,
semana:1,
estado:"Mejorando"
},
{
id:9,
nombre:"Ignacia Herrera",
curso:"6°A",
diagnostico:"TEA",
total:4,
semana:0,
estado:"Mejorando"
},
{
id:10,
nombre:"Vicente Castro",
curso:"6°B",
diagnostico:"TEL",
total:20,
semana:4,
estado:"Riesgo"
},
{
id:11,
nombre:"Martina López",
curso:"6°B",
diagnostico:"TEA",
total:6,
semana:1,
estado:"Mejorando"
},
{
id:12,
nombre:"Tomás Araya",
curso:"6°B",
diagnostico:"TDAH",
total:11,
semana:2,
estado:"Estable"
},
{
id:13,
nombre:"Antonia Vega",
curso:"7°A",
diagnostico:"TEA",
total:3,
semana:0,
estado:"Mejorando"
},
{
id:14,
nombre:"Lucas Fuentes",
curso:"7°A",
diagnostico:"TDAH",
total:14,
semana:2,
estado:"Estable"
},
{
id:15,
nombre:"Amanda Contreras",
curso:"7°B",
diagnostico:"TEL",
total:8,
semana:1,
estado:"Mejorando"
},
{
id:16,
nombre:"Cristóbal Reyes",
curso:"7°B",
diagnostico:"TEA",
total:25,
semana:5,
estado:"Riesgo"
}

];

const historial = {

1:[15,12,10,8,5,3],
2:[22,21,19,18,17,18],
3:[10,8,7,6,5,4],
4:[12,14,17,19,20,22],
5:[14,12,10,9,8,7],
6:[10,10,9,9,10,10],
7:[18,17,16,15,15,15],
8:[15,13,12,11,10,9],
9:[9,8,7,6,5,4],
10:[15,16,17,18,19,20],
11:[11,10,9,8,7,6],
12:[14,14,13,12,11,11],
13:[8,7,6,5,4,3],
14:[18,17,16,15,14,14],
15:[12,11,10,9,8,8],
16:[18,19,21,22,24,25]

};

function cargarTabla(lista){

const tabla =
document.getElementById("tablaEstudiantes");

tabla.innerHTML = "";

lista.forEach(e=>{

tabla.innerHTML += `
<tr>
<td>${e.nombre}</td>
<td>${e.curso}</td>
<td>${e.diagnostico}</td>
<td>${e.total}</td>
<td>${e.semana}</td>
<<td>

<span class="badge ${
e.estado==="Riesgo"
? "bg-danger"
: e.estado==="Estable"
? "bg-warning text-dark"
: "bg-success"
}">
${e.estado}
</span>

</td>
<td>

<button
class="btn btn-primary btn-sm"
onclick="verEstudiante(${e.id})">

Ver

</button>

</td>
</tr>
`;

});

}
function cargarCursos(){

const select =
document.getElementById("filtroCurso");

const cursos = [
...new Set(
estudiantes.map(e=>e.curso)
)
].sort();

cursos.forEach(curso=>{

select.innerHTML += `
<option value="${curso}">
${curso}
</option>
`;

});

}

function aplicarFiltros(){

const texto =
document.getElementById("buscar")
.value
.toLowerCase();

const curso =
document.getElementById("filtroCurso")
.value;

const diagnostico =
document.getElementById("filtroDiagnostico")
.value;

const estado =
document.getElementById("filtroEstado")
.value;

const orden =
document.getElementById("ordenarPor")
.value;

let resultado = [...estudiantes];

resultado = resultado.filter(e=>{

const coincideNombre =
e.nombre.toLowerCase()
.includes(texto);

const coincideCurso =
curso === "" ||
e.curso === curso;

const coincideDiagnostico =
diagnostico === "" ||
e.diagnostico === diagnostico;

const coincideEstado =
estado === "" ||
e.estado === estado;

return (
coincideNombre &&
coincideCurso &&
coincideDiagnostico &&
coincideEstado
);

});

switch(orden){

case "totalDesc":
resultado.sort(
(a,b)=>b.total-a.total
);
break;

case "totalAsc":
resultado.sort(
(a,b)=>a.total-b.total
);
break;

case "semanaDesc":
resultado.sort(
(a,b)=>b.semana-a.semana
);
break;

case "semanaAsc":
resultado.sort(
(a,b)=>a.semana-b.semana
);
break;

}

cargarTabla(resultado);

}
document.addEventListener("DOMContentLoaded",()=>{

    cargarCursos();
    cargarTabla(estudiantes);

    document
    .getElementById("buscar")
    .addEventListener(
        "input",
        aplicarFiltros
    );

    document
    .getElementById("filtroCurso")
    .addEventListener(
        "change",
        aplicarFiltros
    );

    document
    .getElementById("filtroDiagnostico")
    .addEventListener(
        "change",
        aplicarFiltros
    );

    document
    .getElementById("filtroEstado")
    .addEventListener(
        "change",
        aplicarFiltros
    );

    document
    .getElementById("ordenarPor")
    .addEventListener(
        "change",
        aplicarFiltros
    );

});
document.getElementById("totalEstudiantes").textContent =
estudiantes.length;

document.getElementById("totalTEA").textContent =
estudiantes.filter(x=>x.diagnostico==="TEA").length;

document.getElementById("totalTDAH").textContent =
estudiantes.filter(x=>x.diagnostico==="TDAH").length;

document.getElementById("totalRiesgo").textContent =
estudiantes.filter(x=>x.estado==="Riesgo").length;

new Chart(document.getElementById("graficoCursos"),{
    type:"bar",
    data:{
        labels:["5°A","5°B","6°A","6°B","7°A","7°B"],
        datasets:[{
            label:"Desregulaciones",
            data:[35,39,28,37,17,33]
        }]
    }
});

new Chart(document.getElementById("graficoTendencia"),{

type:"line",

data:{
labels:["Ene","Feb","Mar","Abr","May","Jun"],
datasets:[{
label:"Total Desregulaciones",
data:[80,70,58,45,34,25],
fill:false
}]
}

});

let graficoAlumno = null;
let graficoImpacto = null;

function verEstudiante(id){

const alumno =
estudiantes.find(x=>x.id===id);

const datos =
historial[id];

document.getElementById("tituloEstudiante").innerHTML =
`${alumno.nombre} - ${alumno.curso}`;

document.getElementById("datoHoy").innerHTML =
Math.floor(Math.random()*2);

document.getElementById("datoSemana").innerHTML =
alumno.semana;

document.getElementById("datoMes").innerHTML =
alumno.total;

if(graficoAlumno){
graficoAlumno.destroy();
}

graficoAlumno = new Chart(
document.getElementById("graficoAlumno"),
{
    type:"line",
    data:{
        labels:["Ene","Feb","Mar","Abr","May","Jun"],
        datasets:[{
            label:"Desregulaciones",
            data:datos,
            borderWidth:3,
            tension:0.3
        }]
    },
    options:{
        responsive:true,
        maintainAspectRatio:false
    }
});

if(graficoImpacto){
graficoImpacto.destroy();
}

graficoImpacto =
new Chart(
document.getElementById("graficoImpacto"),
{
type:"bar",
data:{
labels:[
"Antes Anticipa",
"Actual"
],
datasets:[{
label:"Incidentes",
data:[
datos[0],
datos[5]
]
}]
}
});

const cambio =
Math.round(
((datos[5]-datos[0])/
datos[0])*100
);

let mensaje="";

if(cambio<0){

mensaje =
`El estudiante presenta una mejora de ${Math.abs(cambio)}% desde el inicio del seguimiento.`;

}
else{

mensaje =
`Se detecta un aumento de ${cambio}% en las desregulaciones. Se recomienda intervención temprana.`;

}

document.getElementById("observacion").innerHTML =
mensaje;

new bootstrap.Modal(
document.getElementById("modalEstudiante")
).show();

}