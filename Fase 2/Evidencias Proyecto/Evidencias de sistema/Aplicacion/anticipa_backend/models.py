# =========================================================
# MODELS.PY
# Cada clase representa una tabla en la base de datos.
# =========================================================
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


# =========================================================
# 0. TIPOS PERSONALIZADOS (ENUMS)
# =========================================================
class TipoSonidoEnum(enum.Enum):
    suave    = 'suave'
    moderado = 'moderado'
    silencio = 'silencio'


class MinutosAnticipacionEnum(enum.Enum):
    dos   = '2'
    cinco = '5'
    diez  = '10'


# =========================================================
# 1. TABLA ROL
# =========================================================
class Rol(Base):
    __tablename__ = "rol"

    id_rol     = Column(Integer, primary_key=True, nullable=False)
    nombre_rol = Column(String(50), nullable=False, unique=True)


# =========================================================
# 2. TABLA USUARIO
# =========================================================
class Usuario(Base):
    __tablename__ = "usuario"

    id_usuario         = Column(Integer, primary_key=True, nullable=False)
    id_rol             = Column(Integer, ForeignKey("rol.id_rol"), nullable=False)
    nombre             = Column(String(100), nullable=False)
    email              = Column(String(100), nullable=False, unique=True)
    password_hash      = Column(String(255), nullable=False)
    fecha_registro     = Column(TIMESTAMP(timezone=True), nullable=False, server_default=text('now()'))
    fecha_nacimiento   = Column(Date, nullable=False)
    codigo_vinculacion = Column(String(7), unique=True, nullable=True)
    puntos_totales     = Column(Integer, default=0)
    curso              = Column(String(100), nullable=True)

    rol = relationship("Rol")


# =========================================================
# 3. TABLA VINCULACION_HISTORIAL
# =========================================================
class VinculacionHistorial(Base):
    __tablename__ = "vinculacion_historial"

    id_vinculo    = Column(Integer, primary_key=True, nullable=False)
    id_adulto     = Column(Integer, ForeignKey("usuario.id_usuario"), nullable=False)
    id_estudiante = Column(Integer, ForeignKey("usuario.id_usuario"), nullable=False)
    fecha_inicio  = Column(TIMESTAMP(timezone=True), nullable=False, server_default=text('now()'))
    fecha_termino = Column(TIMESTAMP(timezone=True), nullable=True)
    motivo_cambio = Column(String(255), nullable=True)

    __table_args__ = (
        Index(
            'idx_un_vinculo_activo',
            'id_adulto',
            'id_estudiante',
            unique=True,
            postgresql_where=text('fecha_termino IS NULL')
        ),
    )

    adulto     = relationship("Usuario", foreign_keys=[id_adulto])
    estudiante = relationship("Usuario", foreign_keys=[id_estudiante])


# =========================================================
# 4. TABLA PICTOGRAMA
# =========================================================
class Pictograma(Base):
    __tablename__ = "pictograma"

    id_pictograma = Column(Integer, primary_key=True, nullable=False)
    nombre_imagen = Column(String(100), nullable=False)
    url           = Column(Text, nullable=False)
    categoria     = Column(String(50), nullable=True)


# =========================================================
# 5. TABLA CATALOGO_ACTIVIDAD
# =========================================================
class CatalogoActividad(Base):
    __tablename__ = "catalogo_actividad"

    id_catalogo            = Column(Integer, primary_key=True, nullable=False)
    nombre_predeterminado  = Column(String(100), nullable=False)
    id_pictograma_sugerido = Column(Integer, ForeignKey("pictograma.id_pictograma"), nullable=True)

    pictograma = relationship("Pictograma")


# =========================================================
# 6. TABLA ACTIVIDAD
# =========================================================
class Actividad(Base):
    __tablename__ = "actividad"

    id_actividad    = Column(Integer, primary_key=True, nullable=False)
    id_estudiante   = Column(Integer, ForeignKey("usuario.id_usuario", ondelete="CASCADE"), nullable=False)
    id_creador      = Column(Integer, ForeignKey("usuario.id_usuario"), nullable=False)
    id_pictograma   = Column(Integer, ForeignKey("pictograma.id_pictograma"), nullable=True)
    id_catalogo     = Column(Integer, ForeignKey("catalogo_actividad.id_catalogo"), nullable=True)
    nombre_tarea    = Column(String(100), nullable=False)
    hora_inicio     = Column(Time, nullable=False)
    hora_fin        = Column(Time, nullable=False)
    es_completada   = Column(Boolean, nullable=False, default=False)
    fecha_actividad = Column(Date, nullable=False)
    fecha_creacion  = Column(TIMESTAMP(timezone=True), nullable=False, server_default=text('now()'))

    estudiante = relationship("Usuario", foreign_keys=[id_estudiante])
    creador    = relationship("Usuario", foreign_keys=[id_creador])
    pictograma = relationship("Pictograma")
    catalogo   = relationship("CatalogoActividad")


# =========================================================
# 7. TABLA CONFIGURACION_ALERTA
# =========================================================
class ConfiguracionAlerta(Base):
    __tablename__ = "configuracion_alerta"

    id_alerta            = Column(Integer, primary_key=True, nullable=False)
    id_actividad         = Column(Integer, ForeignKey("actividad.id_actividad", ondelete="CASCADE"), nullable=False, unique=True)
    minutos_anticipacion = Column(
        Enum(MinutosAnticipacionEnum, values_callable=lambda x: [e.value for e in x]),
        nullable=False,
        default=MinutosAnticipacionEnum.cinco
    )
    tipo_sonido = Column(
        Enum(TipoSonidoEnum, values_callable=lambda x: [e.value for e in x]),
        nullable=False,
        default=TipoSonidoEnum.suave
    )
    parpadeo_visual = Column(Boolean, nullable=False, default=True)

    actividad = relationship("Actividad")


# =========================================================
# 8. TABLA RECOMPENSA_DISPONIBLE
# =========================================================
class RecompensaDisponible(Base):
    __tablename__ = "recompensa_disponible"

    id_recompensa     = Column(Integer, primary_key=True, nullable=False)
    id_estudiante     = Column(Integer, ForeignKey("usuario.id_usuario", ondelete="CASCADE"), nullable=False)
    nombre_recompensa = Column(String(100), nullable=False)
    recompensa_url    = Column(Text, nullable=True)
    meta_estrellas    = Column(Integer, nullable=False, default=5)
    estado_logro      = Column(Boolean, nullable=False, default=False)
    fecha_logro       = Column(TIMESTAMP(timezone=True), nullable=True)

    estudiante = relationship("Usuario")


# =========================================================
# 9. TABLA REGISTRO_ESTRELLA_DIARIA
# =========================================================
class RegistroEstrellaDiaria(Base):
    __tablename__ = "registro_estrella_diaria"

    id_registro       = Column(Integer, primary_key=True, nullable=False)
    id_estudiante     = Column(Integer, ForeignKey("usuario.id_usuario"), nullable=False)
    fecha             = Column(Date, nullable=False, server_default=text('CURRENT_DATE'))
    estrellas_ganadas = Column(Integer, nullable=False, default=0)

    __table_args__ = (
        CheckConstraint('estrellas_ganadas >= 0', name='check_estrellas_ganadas_positivas'),
        UniqueConstraint('id_estudiante', 'fecha', name='unq_estudiante_fecha'),
    )

    estudiante = relationship("Usuario")


# =========================================================
# 10. TABLA HISTORIAL_CUMPLIMIENTO
# =========================================================
class HistorialCumplimiento(Base):
    __tablename__ = "historial_cumplimiento"

    id_log             = Column(Integer, primary_key=True, nullable=False)
    id_actividad       = Column(Integer, ForeignKey("actividad.id_actividad"), nullable=False)
    fecha_cumplimiento = Column(TIMESTAMP(timezone=True), nullable=False, server_default=text('now()'))
    observaciones      = Column(String(255), nullable=True)

    actividad = relationship("Actividad")