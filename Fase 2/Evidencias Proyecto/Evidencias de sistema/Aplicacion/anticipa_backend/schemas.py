# =========================================================
# SCHEMAS.PY
# Cada entidad tiene dos clases:
#   - Create: lo que recibe el endpoint (request body).
#   - Response: lo que devuelve el endpoint (JSON response).
# =========================================================
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import date, datetime, time
from models import TipoSonidoEnum, MinutosAnticipacionEnum


# =========================================================
# CONFIGURACIÓN BASE DE PYDANTIC
# =========================================================
class ConfigBase(BaseModel):
    class Config:
        from_attributes = True  # Pydantic v2
        use_enum_values = True  # Serializa el valor del enum, no el objeto


# =========================================================
# 1. ROL
# =========================================================
class RolCreate(ConfigBase):
    nombre_rol: str


class RolResponse(ConfigBase):
    id_rol:     int
    nombre_rol: str


# =========================================================
# 2. USUARIO
# =========================================================
class UsuarioCreate(ConfigBase):
    id_rol:             int
    nombre:             str
    email:              EmailStr
    password_hash:      str
    fecha_nacimiento:   date
    codigo_vinculacion: Optional[str] = None
    puntos_totales:     Optional[int] = 0
    curso:              Optional[str] = None


class UsuarioResponse(ConfigBase):
    id_usuario:         int
    id_rol:             int
    nombre:             str
    email:              str
    fecha_registro:     datetime
    fecha_nacimiento:   date
    codigo_vinculacion: Optional[str]
    puntos_totales:     Optional[int]
    curso:              Optional[str]
    # Nunca se expone password_hash en la respuesta


# =========================================================
# 3. VINCULACION_HISTORIAL
# =========================================================
class VinculacionCreate(ConfigBase):
    id_adulto:     int
    id_estudiante: int
    motivo_cambio: Optional[str] = None


class VinculacionResponse(ConfigBase):
    id_vinculo:    int
    id_adulto:     int
    id_estudiante: int
    fecha_inicio:  datetime
    fecha_termino: Optional[datetime]
    motivo_cambio: Optional[str]


# =========================================================
# 4. PICTOGRAMA
# =========================================================
class PictogramaCreate(ConfigBase):
    nombre_imagen: str
    url:           str
    categoria:     Optional[str] = None


class PictogramaResponse(ConfigBase):
    id_pictograma: int
    nombre_imagen: str
    url:           str
    categoria:     Optional[str]


# =========================================================
# 5. CATALOGO_ACTIVIDAD
# =========================================================
class CatalogoActividadCreate(ConfigBase):
    nombre_predeterminado:  str
    id_pictograma_sugerido: Optional[int] = None


class CatalogoActividadResponse(ConfigBase):
    id_catalogo:            int
    nombre_predeterminado:  str
    id_pictograma_sugerido: Optional[int]


# =========================================================
# 6. ACTIVIDAD
# =========================================================
class ActividadCreate(ConfigBase):
    id_estudiante:  int
    id_creador:     int
    id_pictograma:  Optional[int] = None
    id_catalogo:    Optional[int] = None
    nombre_tarea:   str
    hora_inicio:    time
    hora_fin:       time
    fecha_actividad: date


class ActividadResponse(ConfigBase):
    id_actividad:   int
    id_estudiante:  int
    id_creador:     int
    id_pictograma:  Optional[int]
    id_catalogo:    Optional[int]
    nombre_tarea:   str
    hora_inicio:    time
    hora_fin:       time
    es_completada:  bool
    fecha_actividad: date
    fecha_creacion: datetime


# =========================================================
# 7. CONFIGURACION_ALERTA
# =========================================================
class ConfiguracionAlertaCreate(ConfigBase):
    id_actividad:         int
    minutos_anticipacion: MinutosAnticipacionEnum = MinutosAnticipacionEnum.cinco
    tipo_sonido:          TipoSonidoEnum          = TipoSonidoEnum.suave
    parpadeo_visual:      bool                    = True


class ConfiguracionAlertaResponse(ConfigBase):
    id_alerta:            int
    id_actividad:         int
    minutos_anticipacion: str
    tipo_sonido:          str
    parpadeo_visual:      bool


# =========================================================
# 8. RECOMPENSA_DISPONIBLE
# =========================================================
class RecompensaCreate(ConfigBase):
    id_estudiante:    int
    nombre_recompensa: str
    recompensa_url:   Optional[str] = None
    meta_estrellas:   int           = 5


class RecompensaResponse(ConfigBase):
    id_recompensa:    int
    id_estudiante:    int
    nombre_recompensa: str
    recompensa_url:   Optional[str]
    meta_estrellas:   int
    estado_logro:     bool
    fecha_logro:      Optional[datetime]


# =========================================================
# 9. REGISTRO_ESTRELLA_DIARIA
# =========================================================
class EstrellaDiariaCreate(ConfigBase):
    id_estudiante:    int
    fecha:            date
    estrellas_ganadas: int = 0


class EstrellaDiariaResponse(ConfigBase):
    id_registro:      int
    id_estudiante:    int
    fecha:            date
    estrellas_ganadas: int


# =========================================================
# 10. HISTORIAL_CUMPLIMIENTO
# =========================================================
class HistorialCreate(ConfigBase):
    id_actividad:  int
    observaciones: Optional[str] = None


class HistorialResponse(ConfigBase):
    id_log:             int
    id_actividad:       int
    fecha_cumplimiento: datetime
    observaciones:      Optional[str]