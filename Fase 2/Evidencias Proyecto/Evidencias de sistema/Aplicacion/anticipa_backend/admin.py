from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from passlib.context import CryptContext
import models
import schemas_admin
from database import engine, get_db

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
router = APIRouter()

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

@router.post("/login")
def admin_login(request: schemas_admin.AdminLogin, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.email == request.email).first()
    if not usuario or not verify_password(request.password, usuario.password_hash):
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")
    if not usuario.es_admin:
        raise HTTPException(status_code=403, detail="No tienes acceso de administrador")
    return {"id_usuario": usuario.id_usuario, "nombre": usuario.nombre, "email": usuario.email}

@router.get("/usuarios/")
def listar_usuarios(db: Session = Depends(get_db)):
    usuarios = db.query(models.Usuario).all()
    return [{
        "id_usuario": u.id_usuario,
        "nombre": u.nombre,
        "email": u.email,
        "rol_id_rol": u.rol_id_rol,
        "es_admin": u.es_admin,
        "curso_id_curso": u.curso_id_curso,
    } for u in usuarios]

@router.patch("/usuarios/{id}")
def editar_usuario(id: int, datos: schemas_admin.UsuarioUpdate, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id_usuario == id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    datos_dict = datos.model_dump(exclude_unset=True)
    if 'password' in datos_dict and datos_dict['password']:
        datos_dict['password_hash'] = hash_password(datos_dict.pop('password'))
    for campo, valor in datos_dict.items():
        setattr(usuario, campo, valor)
    db.commit()
    return {"mensaje": "Usuario actualizado"}

@router.delete("/usuarios/{id}")
def eliminar_usuario(id: int, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id_usuario == id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    db.delete(usuario)
    db.commit()
    return {"mensaje": "Usuario eliminado"}