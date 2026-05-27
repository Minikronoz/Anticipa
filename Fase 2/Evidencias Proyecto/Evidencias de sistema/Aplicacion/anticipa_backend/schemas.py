from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import date, datetime, time
from models import TipoSonidoEnum, MinutosAnticipEnum


class ConfigBase(BaseModel):
    class Config:
        from_attributes = True
        use_enum_values  = True


# ROL
class RolCreate(ConfigBase):
    nombre_rol: str

class RolResponse(ConfigBase):
    id_rol: int
    nombre_rol: str


# CURSO
class CursoCreate(ConfigBase):
    nivel_academico: str
    letra_academica: Optional[str] = None

class CursoResponse(ConfigBase):
    id_curso:        int
    nivel_academico: str
    letra_academica: Optional[str]


# USUARIO
class UsuarioCreate(ConfigBase):
    rol_id_rol:    int
    nombre:        str
    email:         EmailStr
    password_hash: str
    curso_id_curso: Optional[int] = None

class UsuarioResponse(ConfigBase):
    id_usuario:    int
    rol_id_rol:    int
    nombre:        str
    email:         str
    fecha_registro: datetime
    curso_id_curso: Optional[int]


# ESTUDIANTE
class EstudianteCreate(ConfigBase):
    nombre:            str
    fecha_nacimiento:  date
    usuario_id_usuario: int
    curso_id_curso:    int

class EstudianteResponse(ConfigBase):
    id_estudiante:     int
    nombre:            str
    fecha_nacimiento:  date
    codigo_vinculacion: Optional[str]
    puntos_totales:    int
    creado_en:         datetime
    usuario_id_usuario: int
    curso_id_curso:    int

class EstudianteUpdate(ConfigBase):
    nombre:           Optional[str]  = None
    fecha_nacimiento: Optional[date] = None
    curso_id_curso:   Optional[int]  = None


# VINCULACION_HISTORIAL
class VinculacionCreate(ConfigBase):
    usuario_id_usuario: int
    id_estudiante:      int
    rol_id_rol:         int
    motivo_cambio:      Optional[str] = None

class VinculacionResponse(ConfigBase):
    id_vinculo:         int
    usuario_id_usuario: int
    id_estudiante:      int
    rol_id_rol:         int
    fecha_inicio:       datetime
    fecha_termino:      Optional[datetime]
    motivo_cambio:      Optional[str]


# PICTOGRAMA
class PictogramaCreate(ConfigBase):
    nombre_imagen: str
    url:           str
    categoria:     Optional[str] = None

class PictogramaResponse(ConfigBase):
    id_pictograma: int
    nombre_imagen: str
    url:           str
    categoria:     Optional[str]


# CATALOGO_ACTIVIDAD
class CatalogoCreate(ConfigBase):
    nombre_predeterminado:    str
    pictograma_id_pictograma: Optional[int] = None

class CatalogoResponse(ConfigBase):
    id_catalogo:              int
    nombre_predeterminado:    str
    pictograma_id_pictograma: Optional[int]


# ACTIVIDAD
class ActividadCreate(ConfigBase):
    estudiante_id_estudiante:       int
    usuario_id_usuario:             int
    pictograma_id_pictograma:       Optional[int] = None
    catalogo_actividad_id_catalogo: Optional[int] = None
    nombre_tarea:                   str
    hora_inicio:                    time
    hora_fin:                       time
    fecha_actividad:                date

class ActividadResponse(ConfigBase):
    id_actividad:                   int
    estudiante_id_estudiante:       int
    usuario_id_usuario:             int
    pictograma_id_pictograma:       Optional[int]
    catalogo_actividad_id_catalogo: Optional[int]
    nombre_tarea:                   str
    hora_inicio:                    time
    hora_fin:                       time
    es_completada:                  bool
    fecha_actividad:                date
    fecha_creacion:                 datetime

class ActividadUpdate(ConfigBase):
    nombre_tarea:                   Optional[str]  = None
    hora_inicio:                    Optional[time] = None
    hora_fin:                       Optional[time] = None
    fecha_actividad:                Optional[date] = None
    pictograma_id_pictograma:       Optional[int]  = None
    catalogo_actividad_id_catalogo: Optional[int]  = None


# CONFIGURACION_ALERTA
class AlertaCreate(ConfigBase):
    actividad_id_actividad: int
    minutos_anticipacion:   MinutosAnticipEnum = MinutosAnticipEnum.cinco
    tipo_sonido:            TipoSonidoEnum     = TipoSonidoEnum.suave
    parpadeo_visual:        bool               = True

class AlertaResponse(ConfigBase):
    id_alerta:              int
    actividad_id_actividad: int
    minutos_anticipacion:   str
    tipo_sonido:            str
    parpadeo_visual:        bool


# HISTORIAL_CUMPLIMIENTO
class HistorialCreate(ConfigBase):
    actividad_id_actividad: int
    observaciones:          Optional[str] = None

class HistorialResponse(ConfigBase):
    id_log:                 int
    actividad_id_actividad: int
    fecha_cumplimiento:     datetime
    observaciones:          Optional[str]


# RECOMPENSA_DISPONIBLE
class RecompensaCreate(ConfigBase):
    estudiante_id_estudiante: int
    nombre_recompensa:        str
    recompensa_url:           Optional[str] = None
    meta_estrellas:           int           = 5

class RecompensaResponse(ConfigBase):
    id_recompensa:            int
    estudiante_id_estudiante: int
    nombre_recompensa:        str
    recompensa_url:           Optional[str]
    meta_estrellas:           int
    estado_logro:             bool
    fecha_logro:              Optional[datetime]


# REGISTRO_ESTRELLA_DIARIA
class EstrellaCreate(ConfigBase):
    estudiante_id_estudiante: int
    fecha:                    date
    estrellas_ganadas:        int = 0

class EstrellaResponse(ConfigBase):
    id_registro:              int
    estudiante_id_estudiante: int
    fecha:                    date
    estrellas_ganadas:        int


# REGISTRO CON DETECCIÓN DE ROL
class RegistroRequest(BaseModel):
    nombre:            str
    email:             str
    password:          str
    fecha_nacimiento:  Optional[date] = None
    curso_id_curso:    Optional[int] = None


# AUTENTICACION
class LoginRequest(BaseModel):
    email:    str
    password: str

class RecuperarPasswordRequest(BaseModel):
    email: str

class VerificarCodigoRequest(BaseModel):
    email:  str
    codigo: str

class CambiarPasswordRequest(BaseModel):
    email:          str
    codigo:         str
    nueva_password: str
