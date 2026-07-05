Anticipa

Anticipa es una plataforma tecnológica desarrollada para apoyar a niños con Necesidades Educativas Especiales (NEE) mediante un sistema de anticipación visual que facilita la comprensión de rutinas, actividades y cambios en la jornada diaria.

El proyecto nace a partir de una problemática observada en contextos educativos y familiares: muchos niños presentan ansiedad, frustración o desregulación emocional cuando desconocen qué ocurrirá a continuación o enfrentan cambios inesperados en sus rutinas. Anticipa aborda esta necesidad proporcionando una experiencia visual, intuitiva y accesible basada en pictogramas, permitiendo transformar la incertidumbre en una secuencia clara, predecible y comprensible.

Actualmente el sistema se encuentra completamente desarrollado e implementado, integrando una aplicación móvil para estudiantes y una plataforma de administración para docentes y tutores, ofreciendo una solución integral para la planificación, seguimiento y gestión de rutinas.

Objetivo General

Desarrollar una plataforma tecnológica inclusiva que facilite la anticipación de rutinas y actividades en niños con Necesidades Educativas Especiales, promoviendo la autonomía, disminuyendo la ansiedad frente a cambios cotidianos y fortaleciendo el acompañamiento por parte de docentes y familias.

Funcionalidades Implementadas
Gestión de Rutinas
Calendario visual diario, semanal y mensual.
Organización de actividades mediante pictogramas.
Creación de rutinas personalizadas.
Reordenamiento de actividades.
Historial completo de actividades realizadas.
Biblioteca de Pictogramas
Integración con pictogramas ARASAAC.
Más de 33 pictogramas organizados por categorías.
Actividades de:
Higiene.
Alimentación.
Colegio.
Transporte.
Descanso.
Juegos.
Tiempo libre.
Salud.
Sistema de Alertas
Alertas configurables de 2, 5, 10 y 15 minutos antes de cada actividad.
Recordatorios automáticos para facilitar la anticipación.
Notificaciones visuales dentro de la aplicación.
Sistema de Recompensas
Obtención automática de estrellas al completar actividades.
Acumulación de puntos por cumplimiento de rutinas.
Sistema de recompensas canjeables.
Refuerzo positivo para incentivar la autonomía.
Seguimiento del Progreso
Registro histórico de actividades completadas.
Estado diario de cumplimiento.
Visualización del progreso del estudiante.
Seguimiento del avance por parte del tutor y profesor.
Panel Estudiante

Diseñado específicamente para facilitar la interacción del niño.

Incluye:

Modo kiosco simplificado.
Pictogramas de gran tamaño.
Visualización únicamente de las actividades del día.
Navegación sencilla entre días.
Confirmación de actividades con un solo toque.
Visualización de estrellas acumuladas.
Panel Tutor

Permite realizar el seguimiento del estudiante.

Funciones implementadas:

Vinculación mediante código único.
Visualización de los hijos asociados.
Consulta del progreso diario.
Revisión del historial de actividades.
Consulta de estrellas acumuladas.
Gestión de rutinas asignadas.
Panel Profesor

Orientado a la administración académica.

Permite:

Registrar estudiantes.
Asociar estudiantes mediante código único.
Organización por cursos.
Administración de rutinas.
Creación y modificación de actividades.
Seguimiento del cumplimiento de cada alumno.
Sistema de Vinculación

El sistema incorpora un mecanismo seguro de asociación entre usuarios.

Cada estudiante posee un código único de siete caracteres que permite:

Vinculación del profesor.
Vinculación del tutor.
Asociación sin duplicidad de información.
Gestión centralizada de relaciones.
Seguridad

Se implementó un sistema completo de autenticación y autorización.

Incluye:

Inicio de sesión seguro.
Recuperación de contraseña mediante correo electrónico.
Autenticación basada en JWT.
Control de acceso mediante RBAC.
Detección automática del rol según el dominio del correo electrónico.
Protección de rutas y recursos.
Tecnologías Utilizadas
Frontend
Flutter
Dart
Backend
FastAPI
Python
Base de Datos
PostgreSQL
Supabase
Persistencia
SQLAlchemy
Autenticación
JWT
Recuperación de Contraseña
Yagmail
Control de Versiones
GitHub
Metodología
Kanban como metodología principal para la gestión continua del proyecto.
Arquitectura
Arquitectura cliente-servidor basada en API REST.
Base de datos centralizada.
Comunicación segura entre frontend, backend y base de datos.
Escalabilidad

La arquitectura fue diseñada considerando el crecimiento futuro de la plataforma.

El sistema permite:

Incorporar nuevos establecimientos educacionales.
Agregar múltiples cursos por institución.
Soportar miles de estudiantes sin modificar la arquitectura principal.
Escalar horizontalmente el backend mediante FastAPI.
Optimizar PostgreSQL utilizando índices, replicación y mejoras de rendimiento.
Incorporar nuevas funcionalidades sin afectar los módulos existentes gracias a una arquitectura desacoplada basada en API REST.
Implementar balanceo de carga y nuevos servidores cuando aumente la demanda.
Adaptarse a un modelo SaaS para atender múltiples establecimientos desde una única plataforma.
Impacto Alcanzado

Anticipa constituye una herramienta tecnológica enfocada en mejorar la experiencia diaria de niños con Necesidades Educativas Especiales mediante una solución accesible y centrada en el usuario.

La plataforma contribuye a:

Reducir la incertidumbre frente a las rutinas diarias.
Disminuir la ansiedad generada por cambios inesperados.
Favorecer la autorregulación emocional.
Promover la autonomía progresiva.
Facilitar la comprensión temporal mediante apoyos visuales.
Mejorar la comunicación entre docentes, tutores y estudiantes.
Apoyar procesos pedagógicos inclusivos.
Fortalecer el seguimiento del progreso de cada estudiante.
Equipo de Desarrollo
Carlos Catalán
Sebastián Solar
Agustín Jara
Estado del Proyecto

Estado: Proyecto finalizado.

Resultado alcanzado
Desarrollo completo de la aplicación móvil.
Desarrollo completo de la plataforma web.
Integración entre frontend, backend y base de datos.
Implementación del sistema de autenticación y control de acceso.
Integración de rutinas, pictogramas, alertas y sistema de recompensas.
Validación funcional de todos los módulos principales.
Corrección de incidencias críticas detectadas durante el desarrollo.
Documentación técnica y de usuario completamente finalizada.
Sistema preparado para producción y futuras ampliaciones.
Trabajo Futuro

Como evolución del proyecto, Anticipa podrá incorporar:

Inteligencia Artificial para sugerir rutinas personalizadas según el comportamiento del estudiante.
Aprendizaje basado en patrones de uso.
Integración con calendarios escolares.
Notificaciones Push mediante Firebase Cloud Messaging.
Panel administrativo para establecimientos educacionales.
Estadísticas avanzadas para docentes, tutores y directivos.
Sincronización en tiempo real.
Funcionamiento en modo offline.
Soporte para múltiples instituciones educativas bajo un modelo SaaS.
Integración con plataformas educativas y sistemas de gestión escolar.
