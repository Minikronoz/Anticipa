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



@router.get("/estadisticas")
def obtener_estadisticas(db: Session = Depends(get_db)):

    usuarios = db.query(models.Usuario).all()

    total = len(usuarios)

    estudiantes = len([
        u for u in usuarios
        if u.rol_id_rol == 4
    ])

    profesores = len([
        u for u in usuarios
        if u.rol_id_rol == 2
    ])

    tutores = len([
        u for u in usuarios
        if u.rol_id_rol == 3
    ])

    admins = len([
        u for u in usuarios
        if u.es_admin
    ])

    return {
        "total_usuarios": total,
        "estudiantes": estudiantes,
        "profesores": profesores,
        "tutores": tutores,
        "administradores": admins
    }



@router.post("/usuarios")
def crear_usuario(
    datos: schemas_admin.UsuarioCreate,
    db: Session = Depends(get_db)
):

    existe = db.query(models.Usuario).filter(
        models.Usuario.email == datos.email
    ).first()

    if existe:
        raise HTTPException(
            status_code=400,
            detail="El correo ya existe"
        )

    nuevo = models.Usuario(
        nombre=datos.nombre,
        email=datos.email,
        password_hash=hash_password(datos.password),
        rol_id_rol=datos.rol_id_rol,
        es_admin=datos.es_admin,
        curso_id_curso=datos.curso_id_curso
    )

    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    return {
        "mensaje": "Usuario creado",
        "id_usuario": nuevo.id_usuario
    }

# =========================
# ESTUDIANTES
# =========================

@router.get("/estudiantes")
def listar_estudiantes(db: Session = Depends(get_db)):

    estudiantes = db.query(models.Estudiante).all()

    resultado = []

    for e in estudiantes:

        curso = None

        if e.curso_r:
            curso = f"{e.curso_r.nivel_academico}{e.curso_r.letra_academica}"

        resultado.append({
            "id_estudiante": e.id_estudiante,
            "nombre": e.nombre,
            "fecha_nacimiento": e.fecha_nacimiento,
            "codigo_vinculacion": e.codigo_vinculacion,
            "puntos_totales": e.puntos_totales,
            "curso": curso
        })

    return resultado

@router.get("/estudiantes/{id}")
def obtener_estudiante(
    id: int,
    db: Session = Depends(get_db)
):

    estudiante = db.query(
        models.Estudiante
    ).filter(
        models.Estudiante.id_estudiante == id
    ).first()

    if not estudiante:
        raise HTTPException(
            status_code=404,
            detail="Estudiante no encontrado"
        )

    curso = None

    if estudiante.curso_r:
        curso = f"{estudiante.curso_r.nivel_academico}{estudiante.curso_r.letra_academica}"

    return {
        "id_estudiante": estudiante.id_estudiante,
        "nombre": estudiante.nombre,
        "fecha_nacimiento": estudiante.fecha_nacimiento,
        "codigo_vinculacion": estudiante.codigo_vinculacion,
        "puntos_totales": estudiante.puntos_totales,
        "curso": curso
    }

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