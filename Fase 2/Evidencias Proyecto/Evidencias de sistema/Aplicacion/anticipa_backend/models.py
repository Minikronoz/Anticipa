import enum
from sqlalchemy import (
    Column, Integer, String, Date, Boolean,
    ForeignKey, Enum, Text, Time,
    CheckConstraint, UniqueConstraint, Index
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql.sqltypes import TIMESTAMP
from sqlalchemy.sql.expression import text
from database import Base

# ── Enums para alertas ────────────────────────────────────
class TipoSonidoEnum(enum.Enum):
    suave    = 'suave'
    moderado = 'moderado'
    silencio = 'silencio'

class MinutosAnticipEnum(enum.Enum):
    dos    = '2'
    cinco  = '5'
    diez   = '10'
    quince = '15'


# ── Tabla: Colegio (institución educativa) ──
class Colegio(Base):
    __tablename__ = "colegio"
    id_colegio         = Column(Integer, primary_key=True)
    nombre             = Column(String(100), nullable=False)
    rut                = Column(String(20), unique=True, nullable=True)
    direccion          = Column(String(255), nullable=True)
    telefono           = Column(String(20), nullable=True)
    correo             = Column(String(100), nullable=True)
    contacto_nombre    = Column(String(100), nullable=True)
    activo             = Column(Boolean, nullable=False, default=True)
    plan               = Column(String(20), nullable=False, default="basico")
    fecha_contrato     = Column(Date, nullable=True)
    fecha_vencimiento  = Column(Date, nullable=True)

    cursos = relationship("Curso", back_populates="colegio_r")


# ── Tabla: Roles del sistema (Admin, Profesor, Tutor, Estudiante) ──
class Rol(Base):
    __tablename__ = "rol"
    id_rol     = Column(Integer, primary_key=True)
    nombre_rol = Column(String(50), nullable=False, unique=True)


# ── Tabla: Cursos académicos ──
class Curso(Base):
    __tablename__ = "curso"
    id_curso         = Column(Integer, primary_key=True)
    nivel_academico  = Column(String(10), nullable=False)
    letra_academica  = Column(String(1), nullable=True)
    colegio_id_colegio = Column(Integer, ForeignKey("colegio.id_colegio"), nullable=True)

    colegio_r = relationship("Colegio", back_populates="cursos")


# ── Tabla: Usuarios que inician sesión (todos los roles) ──
class Usuario(Base):
    __tablename__ = "usuario"
    id_usuario         = Column(Integer, primary_key=True)
    rol_id_rol         = Column(Integer, ForeignKey("rol.id_rol"), nullable=False)
    nombre             = Column(String(100), nullable=False)
    email              = Column(String(100), nullable=False, unique=True)
    password_hash      = Column(String(255), nullable=False)
    fecha_registro     = Column(TIMESTAMP(timezone=True), nullable=False, server_default=text('now()'))
    reset_token        = Column(String(100), unique=True, nullable=True)
    reset_token_expiry = Column(TIMESTAMP(timezone=True), nullable=True)
    curso_id_curso     = Column(Integer, ForeignKey("curso.id_curso"), nullable=True)
    es_admin           = Column(Boolean, default=False, nullable=False)
    codigo_vinculacion = Column(String(10), unique=True, nullable=True)
    registrado         = Column(Boolean, default=False, nullable=False)

    rol    = relationship("Rol")
    curso  = relationship("Curso")
    encuestas = relationship("EncuestaDiaria")


# ── Tabla: Estudiantes (niños con TEA/NEE). 1:1 con Usuario ──
class Estudiante(Base):
    __tablename__ = "estudiante"
    id_estudiante      = Column(Integer, primary_key=True)
    nombre             = Column(String(100), nullable=False)
    fecha_nacimiento   = Column(Date, nullable=False)
    codigo_vinculacion = Column(String(7), unique=True, nullable=True)
    puntos_totales     = Column(Integer, nullable=False, default=0)
    diagnostico        = Column(String(50), nullable=True)
    estado             = Column(String(20), nullable=True)
    creado_en          = Column(TIMESTAMP(timezone=True), nullable=False, server_default=text('now()'))
    usuario_id_usuario = Column(Integer, ForeignKey("usuario.id_usuario"), nullable=False)
    curso_id_curso     = Column(Integer, ForeignKey("curso.id_curso"), nullable=False)

    creador = relationship("Usuario", foreign_keys=[usuario_id_usuario])
    curso_r = relationship("Curso", foreign_keys=[curso_id_curso])


# ── Tabla: Vínculo adulto↔estudiante (N:M, con historial) ──
class VinculacionHistorial(Base):
    __tablename__ = "vinculacion_historial"
    id_vinculo         = Column(Integer, primary_key=True)
    usuario_id_usuario = Column(Integer, ForeignKey("usuario.id_usuario"), nullable=False)
    id_estudiante      = Column(Integer, ForeignKey("estudiante.id_estudiante"), nullable=False)
    rol_id_rol         = Column(Integer, ForeignKey("rol.id_rol"), nullable=False)
    fecha_inicio       = Column(TIMESTAMP(timezone=True), nullable=False, server_default=text('now()'))
    fecha_termino      = Column(TIMESTAMP(timezone=True), nullable=True)
    motivo_cambio      = Column(String(255), nullable=True)

    __table_args__ = (
        Index('idx_un_vinculo_activo', 'usuario_id_usuario', 'id_estudiante',
              unique=True, postgresql_where=text('fecha_termino IS NULL')),
    )

    usuario    = relationship("Usuario", foreign_keys=[usuario_id_usuario])
    estudiante = relationship("Estudiante", foreign_keys=[id_estudiante])
    rol        = relationship("Rol", foreign_keys=[rol_id_rol])


# ── Tabla: Catálogo de pictogramas (ARASAAC + personalizados) ──
class Pictograma(Base):
    __tablename__ = "pictograma"
    id_pictograma = Column(Integer, primary_key=True)
    nombre_imagen = Column(String(100), nullable=False)
    url           = Column(Text, nullable=False)
    categoria     = Column(String(50), nullable=True)


# ── Tabla: Actividades predefinidas reutilizables ──
class CatalogoActividad(Base):
    __tablename__ = "catalogo_actividad"
    id_catalogo              = Column(Integer, primary_key=True)
    nombre_predeterminado    = Column(String(100), nullable=False)
    pictograma_id_pictograma = Column(Integer, ForeignKey("pictograma.id_pictograma"), nullable=True)
    pictograma = relationship("Pictograma")


# ── Tabla: Actividades/rutinas diarias asignadas a un estudiante ──
class Actividad(Base):
    __tablename__ = "actividad"
    id_actividad                   = Column(Integer, primary_key=True)
    estudiante_id_estudiante       = Column(Integer, ForeignKey("estudiante.id_estudiante", ondelete="CASCADE"), nullable=False)
    usuario_id_usuario             = Column(Integer, ForeignKey("usuario.id_usuario"), nullable=False)
    pictograma_id_pictograma       = Column(Integer, ForeignKey("pictograma.id_pictograma"), nullable=True)
    catalogo_actividad_id_catalogo = Column(Integer, ForeignKey("catalogo_actividad.id_catalogo"), nullable=True)
    nombre_tarea                   = Column(String(100), nullable=False)
    hora_inicio                    = Column(Time, nullable=False)
    hora_fin                       = Column(Time, nullable=False)
    es_completada                  = Column(Boolean, nullable=False, default=False)
    fecha_actividad                = Column(Date, nullable=False)
    fecha_creacion                 = Column(TIMESTAMP(timezone=True), nullable=False, server_default=text('now()'))

    estudiante = relationship("Estudiante", foreign_keys=[estudiante_id_estudiante])
    creador    = relationship("Usuario", foreign_keys=[usuario_id_usuario])
    pictograma = relationship("Pictograma")
    catalogo   = relationship("CatalogoActividad")


# ── Tabla: Configuración de alerta 1:1 por actividad ──
class ConfiguracionAlerta(Base):
    __tablename__ = "configuracion_alerta"
    id_alerta              = Column(Integer, primary_key=True)
    actividad_id_actividad = Column(Integer, ForeignKey("actividad.id_actividad", ondelete="CASCADE"), nullable=False, unique=True)
    minutos_anticipacion   = Column(
        Enum(MinutosAnticipEnum, values_callable=lambda x: [e.value for e in x]),
        nullable=False, default=MinutosAnticipEnum.cinco
    )
    tipo_sonido = Column(
        Enum(TipoSonidoEnum, values_callable=lambda x: [e.value for e in x]),
        nullable=False, default=TipoSonidoEnum.suave
    )
    parpadeo_visual = Column(Boolean, nullable=False, default=True)
    actividad = relationship("Actividad")


# ── Tabla: Registro de actividades completadas ──
class HistorialCumplimiento(Base):
    __tablename__ = "historial_cumplimiento"
    id_log                 = Column(Integer, primary_key=True)
    actividad_id_actividad = Column(Integer, ForeignKey("actividad.id_actividad"), nullable=False)
    fecha_cumplimiento     = Column(TIMESTAMP(timezone=True), nullable=False, server_default=text('now()'))
    observaciones          = Column(String(255), nullable=True)
    actividad = relationship("Actividad")


# ── Tabla: Recompensas canjeables con estrellas ──
class RecompensaDisponible(Base):
    __tablename__ = "recompensa_disponible"
    id_recompensa            = Column(Integer, primary_key=True)
    estudiante_id_estudiante = Column(Integer, ForeignKey("estudiante.id_estudiante", ondelete="CASCADE"), nullable=False)
    nombre_recompensa        = Column(String(100), nullable=False)
    recompensa_url           = Column(Text, nullable=True)
    meta_estrellas           = Column(Integer, nullable=False, default=5)
    estado_logro             = Column(Boolean, nullable=False, default=False)
    fecha_logro              = Column(TIMESTAMP(timezone=True), nullable=True)
    estudiante = relationship("Estudiante")


# ── Tabla: Estrellas ganadas por estudiante por día ──
class RegistroEstrellaDiaria(Base):
    __tablename__ = "registro_estrella_diaria"
    id_registro              = Column(Integer, primary_key=True)
    estudiante_id_estudiante = Column(Integer, ForeignKey("estudiante.id_estudiante"), nullable=False)
    fecha                    = Column(Date, nullable=False, server_default=text('CURRENT_DATE'))
    estrellas_ganadas        = Column(Integer, nullable=False, default=0)

    __table_args__ = (
        CheckConstraint('estrellas_ganadas >= 0', name='chk_estrellas_positivas'),
        UniqueConstraint('estudiante_id_estudiante', 'fecha', name='unq_estudiante_fecha'),
    )
    estudiante = relationship("Estudiante")


class EncuestaDiaria(Base):
    __tablename__ = "encuesta_diaria"

    id_encuesta = Column(Integer, primary_key=True)

    estudiante_id_estudiante = Column(
        Integer,
        ForeignKey("estudiante.id_estudiante", ondelete="CASCADE"),
        nullable=False
    )

    usuario_id_usuario = Column(
        Integer,
        ForeignKey("usuario.id_usuario"),
        nullable=False
    )

    fecha = Column(
        Date,
        nullable=False,
        server_default=text("CURRENT_DATE")
    )

    tuvo_desregulacion = Column(
        Boolean,
        nullable=False
    )

    cantidad = Column(
        Integer,
        nullable=True
    )

    motivo = Column(
        String(100),
        nullable=True
    )

    otro_motivo = Column(
        Text,
        nullable=True
    )

    observacion = Column(
        Text,
        nullable=True
    )

    estudiante = relationship("Estudiante")
    usuario = relationship("Usuario")
