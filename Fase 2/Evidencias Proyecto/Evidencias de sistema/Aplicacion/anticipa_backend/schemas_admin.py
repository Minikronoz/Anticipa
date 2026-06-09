from pydantic import BaseModel
from typing import Optional

class AdminLogin(BaseModel):
    email: str
    password: str

class UsuarioResponse(BaseModel):
    id_usuario: int
    nombre: str
    email: str
    rol_id_rol: int
    es_admin: bool
    curso_id_curso: Optional[int]

class UsuarioUpdate(BaseModel):
    nombre: Optional[str] = None
    email: Optional[str] = None
    rol_id_rol: Optional[int] = None
    curso_id_curso: Optional[int] = None
    es_admin: Optional[bool] = None
    password: Optional[str] = None