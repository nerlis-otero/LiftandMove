from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from uuid import uuid4
from pydantic import BaseModel, EmailStr
from jose import jwt, JWTError

import pymysql
import pymysql.cursors
import bcrypt

from datetime import datetime, timedelta, timezone, date
from typing import Any, List, Optional
import os
from dotenv import load_dotenv

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY")

DB_HOST = os.getenv("DB_HOST")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_NAME = os.getenv("DB_NAME")

# Fallbacks para no romper si falta .env
if SECRET_KEY is None:
    raise RuntimeError("SECRET_KEY no configurado en .env")


if DB_HOST is None:
    raise RuntimeError("DB_HOST no configurado en .env")
if DB_USER is None:
    raise RuntimeError("DB_USER no configurado en .env")
if DB_PASSWORD is None:
    raise RuntimeError("DB_PASSWORD no configurado en .env")
if DB_NAME is None:
    raise RuntimeError("DB_NAME no configurado en .env")





ALGORITHM = "HS256"
TOKEN_EXPIRA_EN_MINUTOS = 60

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor
    )


# get_db_connection() definido arriba con variables de entorno


class UserDataRegister(BaseModel):
    idUsu: str
    nombreUsu: str
    correoUsu: EmailStr
    contrasenha: str
    sexo: str
    altura_cm: int
    peso: int
    objetivo_entreno: str

class UserDataLogin(BaseModel):
    nombreUsu: str
    contrasenha: str

class UsuarioActual(BaseModel):
    idUsu: str
    nombreUsu: str
    correoUsu: str
    esAdmin: bool = False

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(
        plain_password.encode('utf-8'),
        hashed_password.encode('utf-8')
    )

def get_password_hash(password: str) -> str:
    return bcrypt.hashpw(
        password.encode('utf-8'),
        bcrypt.gensalt()
    ).decode('utf-8')

def crear_token_acceso(datos: dict) -> str:
    payload = datos.copy()
    expiracion = datetime.now(timezone.utc) + timedelta(minutes=TOKEN_EXPIRA_EN_MINUTOS)
    payload.update({"exp": expiracion})
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return token

def get_usuario_actual(token: str = Depends(oauth2_scheme)) -> UsuarioActual:

    error_credenciales = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Credenciales invalidas o token expirado",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        id_usu: str = payload.get("sub")
        if id_usu is None:
            raise error_credenciales
    except JWTError:
        raise error_credenciales

    
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT idUsu, nombreUsu, correoUsu, esAdmin FROM usuarios WHERE idUsu = %s",
                (id_usu,)
            )
            fila = cursor.fetchone()
    finally:
        connection.close()

    if fila is None:
        raise error_credenciales

    return UsuarioActual(**fila)

app = FastAPI(title="LiftMove API", version="1.0.0") 
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"message": "API funcionando correctamente"}


@app.get("/me")
def quien_soy(usuario: UsuarioActual = Depends(get_usuario_actual)):
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT idUsu, nombreUsu, correoUsu, sexo, altura_cm, peso, objetivo_entreno, esAdmin FROM usuarios WHERE idUsu = %s",
                (usuario.idUsu,)
            )
            return cursor.fetchone()
    finally:
        connection.close()

@app.post("/register")
def register(data: UserDataRegister) -> Any:
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM usuarios WHERE idUsu = %s", (data.idUsu,))
            if cursor.fetchone():
                raise HTTPException(status_code=400, detail="El id del usuario ya existe")

            cursor.execute("SELECT * FROM usuarios WHERE nombreUsu = %s", (data.nombreUsu,))
            if cursor.fetchone():
                raise HTTPException(status_code=400, detail="El nombre de usuario ya existe")

            cursor.execute("SELECT * FROM usuarios WHERE correoUsu = %s", (data.correoUsu,))
            if cursor.fetchone():
                raise HTTPException(status_code=400, detail="El correo ya está registrado")

            if data.sexo not in ["M", "F"]:
                raise HTTPException(status_code=400, detail="El sexo debe ser 'M' o 'F'")

            
            hashed_password = get_password_hash(data.contrasenha)

            sql = """
                INSERT INTO usuarios
                (idUsu, nombreUsu, correoUsu, contrasenha, sexo, altura_cm, peso, objetivo_entreno)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """
            cursor.execute(sql, (
                data.idUsu,
                data.nombreUsu,
                data.correoUsu,
                hashed_password,
                data.sexo,
                data.altura_cm,
                data.peso,
                data.objetivo_entreno
            ))
            connection.commit()

            return {"success": True, "message": "Usuario creado exitosamente"}
    finally:
        connection.close()

@app.post("/login")
def login(data: UserDataLogin) -> Any:
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT * FROM usuarios WHERE nombreUsu = %s",
                (data.nombreUsu,)
            )
            user = cursor.fetchone()

            
            if not user or not verify_password(data.contrasenha, user['contrasenha']):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Credenciales incorrectas"
                )

            
            token = crear_token_acceso({
                "sub": user["idUsu"],
                "nombreUsu": user["nombreUsu"],
                "esAdmin": bool(user["esAdmin"])
            })

            return {
                "success": True,
                "message": "Autenticacion exitosa",
                "access_token": token,
                "token_type": "bearer",
                "nombreUsu": user["nombreUsu"],
                "esAdmin": bool(user["esAdmin"])
            }
    finally:
        connection.close()
        
def get_admin_usuario(usuario: UsuarioActual = Depends(get_usuario_actual)):
    if not usuario.esAdmin:
        raise HTTPException(status_code=403, detail="Acceso denegado")
    return usuario

@app.get("/admin/usuarios")
def admin_listar_usuarios(admin: UsuarioActual = Depends(get_admin_usuario)):
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT idUsu, nombreUsu, correoUsu, sexo, peso, altura_cm, objetivo_entreno, esAdmin FROM usuarios")
            return cursor.fetchall()
    finally:
        connection.close()

@app.get("/check-usuario/{nombreUsu}")
def check_usuario(nombreUsu: str):
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT 1 FROM usuarios WHERE nombreUsu = %s LIMIT 1",
                (nombreUsu,),
            )
            if cursor.fetchone():
                raise HTTPException(status_code=409, detail="Usuario existente")
            return {"disponible": True}
    finally:
        connection.close()


@app.delete("/admin/usuarios/{idUsu}")
def admin_eliminar_usuario(idUsu: str, admin: UsuarioActual = Depends(get_admin_usuario)):
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            # 1. Primero eliminar ejercicios de las rutinas del usuario
            cursor.execute("""
                DELETE re FROM rutina_ejercicio re
                INNER JOIN rutina_plantilla rp ON re.idPlantilla = rp.idPlantilla
                WHERE rp.idUsu = %s
            """, (idUsu,))
            
            # 2. Eliminar días de las rutinas del usuario
            cursor.execute("""
                DELETE rd FROM rutina_dias rd
                INNER JOIN rutina_plantilla rp ON rd.idPlantilla = rp.idPlantilla
                WHERE rp.idUsu = %s
            """, (idUsu,))
            
            # 3. Eliminar las plantillas de rutina
            cursor.execute("DELETE FROM rutina_plantilla WHERE idUsu = %s", (idUsu,))
            
            # 4. Ahora sí eliminar el usuario
            cursor.execute("DELETE FROM usuarios WHERE idUsu = %s", (idUsu,))
            
            connection.commit()
            return {"success": True, "message": "Usuario eliminado exitosamente"}
    except Exception as e:
        connection.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        connection.close()

# ─── EJERCICIOS ───────────────────────────────────────────

@app.get("/ejercicios")
def get_ejercicios(
    skip: int = 0,
    limit: int = 20,
    categoria: str = None,
    equipamiento: str = None,
    nivel: str = None
):
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            query = "SELECT idEjercicio, nombreEj, tipo, equipamiento, nivel FROM ejercicios WHERE 1=1"
            params = []
            if categoria:
                query += " AND tipo = %s"
                params.append(categoria)
            if equipamiento:
                query += " AND equipamiento = %s"
                params.append(equipamiento)
            if nivel:
                query += " AND nivel = %s"
                params.append(nivel)
            query += " LIMIT %s OFFSET %s"
            params.extend([limit, skip])
            cursor.execute(query, params)
            return cursor.fetchall()
    finally:
        connection.close()

@app.get("/ejercicios/buscar")
def buscar_ejercicios(q: str):
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT idEjercicio, nombreEj, tipo, equipamiento, nivel FROM ejercicios WHERE nombreEj LIKE %s LIMIT 20",
                (f"%{q}%",)
            )
            return cursor.fetchall()
    finally:
        connection.close()

@app.get("/ejercicios/por-musculo")
def ejercicios_por_musculo(musculo: str, limit: int = 30):
    """Ejercicios cuyo músculo primario coincide (rol = 1 en ejercicio_musculo)."""
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT DISTINCT e.idEjercicio, e.nombreEj, e.tipo, e.equipamiento, e.nivel
                FROM ejercicios e
                JOIN ejercicio_musculo em ON e.idEjercicio = em.idEjercicio
                JOIN musculos m ON em.idMusculo = m.idMusculo
                WHERE em.rol = 1 AND m.idMusculo = %s
                ORDER BY e.nombreEj
                LIMIT %s
                """,
                (musculo, limit),
            )
            return cursor.fetchall()
    finally:
        connection.close()

@app.get("/ejercicios/por-musculos")
def ejercicios_por_musculos(musculos: str, limit: int = 40):
    """Varios músculos primarios separados por coma (ej. espalda,dorsales)."""
    nombres = [m.strip() for m in musculos.split(",") if m.strip()]
    if not nombres:
        raise HTTPException(status_code=400, detail="Indica al menos un músculo")
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            placeholders = ", ".join(["%s"] * len(nombres))
            cursor.execute(
                f"""
                SELECT DISTINCT e.idEjercicio, e.nombreEj, e.tipo, e.equipamiento, e.nivel
                FROM ejercicios e
                JOIN ejercicio_musculo em ON e.idEjercicio = em.idEjercicio
                JOIN musculos m ON em.idMusculo = m.idMusculo
                WHERE em.rol = 1 AND m.idMusculo IN ({placeholders})
                ORDER BY e.nombreEj
                LIMIT %s
                """,
                (*nombres, limit),
            )
            return cursor.fetchall()
    finally:
        connection.close()

@app.get("/ejercicios/{ejercicio_id}")
def get_ejercicio(ejercicio_id: str):
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT * FROM ejercicios WHERE idEjercicio = %s",
                (ejercicio_id,)
            )
            ej = cursor.fetchone()
            if not ej:
                raise HTTPException(status_code=404, detail="Ejercicio no encontrado")

            # Traer músculos
            cursor.execute("""
                SELECT m.nombreMusc, em.rol
                FROM ejercicio_musculo em
                JOIN musculos m ON em.idMusculo = m.idMusculo
                WHERE em.idEjercicio = %s
            """, (ejercicio_id,))
            musculos = cursor.fetchall()
            ej["musculos"] = musculos
            return ej
    finally:
        connection.close()

@app.get("/categorias")
def get_categorias():
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT DISTINCT tipo FROM ejercicios WHERE tipo IS NOT NULL ORDER BY tipo")
            rows = cursor.fetchall()
            return [r["tipo"] for r in rows]
    finally:
        connection.close()

@app.get("/musculos")
def get_musculos():
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM musculos ORDER BY nombreMusc")
            return cursor.fetchall()
    finally:
        connection.close()
# ─── AGREGAR AL FINAL DE main.py ───────────────────────────────────────────
# Asegúrate de tener: from uuid import uuid4  (ya debe estar arriba)

from pydantic import BaseModel
from typing import List

# ── Modelos ──────────────────────────────────────────────────────────────────

class EjercicioPlantilla(BaseModel):
    idEjercicio: str
    series: int
    repeticiones: int
    peso_kg: float | None = None

# Compatibilidad con Flutter: algunos clientes pueden enviar "peso" en lugar de "peso_kg"
# (o enviar ambos). En el endpoint se normaliza.


class GuardarPlantillaRequest(BaseModel):
    idUsu: str
    nombre: str
    fecha_inicio: str        # "2025-05-18"
    fecha_fin: str           # "2025-06-18"
    dias_semana: List[int]   # [0,1] = Lunes y Martes (0=Lun...6=Dom)
    ejercicios: List[EjercicioPlantilla]

# ── Guardar plantilla de rutina ───────────────────────────────────────────────

@app.post("/rutinas")
def guardar_rutina(data: GuardarPlantillaRequest):
    if not data.dias_semana:
        raise HTTPException(status_code=400, detail="Debes seleccionar al menos un día")
    if not data.ejercicios:
        raise HTTPException(status_code=400, detail="Debes agregar al menos un ejercicio")

    # Normaliza la carga recibida para compatibilidad con Flutter
    # (clientes pueden mandar "peso" en lugar de "peso_kg" o ambos).
    for ej in data.ejercicios:
        if ej.peso_kg is None:
            ej.peso_kg = 0.0

    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            id_plantilla = str(uuid4())

            # 1. Insertar plantilla
            cursor.execute(
                """
                INSERT INTO rutina_plantilla (idPlantilla, idUsu, nombre, fecha_inicio, fecha_fin)
                VALUES (%s, %s, %s, %s, %s)
                """,
                (id_plantilla, data.idUsu, data.nombre, data.fecha_inicio, data.fecha_fin)
            )

            # 2. Insertar días de la semana
            for dia in data.dias_semana:
                cursor.execute(
                    "INSERT INTO rutina_dias (idPlantilla, dia_semana) VALUES (%s, %s)",
                    (id_plantilla, dia)
                )

            # 3. Insertar ejercicios
            for orden, ej in enumerate(data.ejercicios):
                cursor.execute(
                    """
                    INSERT INTO rutina_ejercicio
                        (idRutinaEj, idPlantilla, idEjercicio, series, repeticiones, peso_kg, orden)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """,
                    (str(uuid4()), id_plantilla, ej.idEjercicio,
                     ej.series, ej.repeticiones, ej.peso_kg, orden + 1)
                )

            connection.commit()
            return {"success": True, "idPlantilla": id_plantilla}

    except Exception as e:
        connection.rollback()
        raise HTTPException(status_code=500, detail=f"Error al guardar: {str(e)}")
    finally:
        connection.close()

# ── Consultar rutinas de un usuario para una fecha específica ─────────────────

@app.get("/rutinas/{idUsu}")
def get_rutinas_por_fecha(idUsu: str, fecha: str):
    """
    Devuelve las rutinas que aplican para la fecha dada.
    Filtra por: fecha dentro del rango inicio-fin Y día de semana coincide.
    Ejemplo: GET /rutinas/USU001?fecha=2025-05-20
    """
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT 
                    rp.idPlantilla,
                    rp.nombre,
                    rp.fecha_inicio,
                    rp.fecha_fin,
                    COUNT(re.idRutinaEj) AS total_ejercicios
                FROM rutina_plantilla rp
                JOIN rutina_dias rd ON rp.idPlantilla = rd.idPlantilla
                LEFT JOIN rutina_ejercicio re ON rp.idPlantilla = re.idPlantilla
                WHERE rp.idUsu = %s
                  AND %s BETWEEN rp.fecha_inicio AND rp.fecha_fin
                  AND rd.dia_semana = WEEKDAY(%s)
                GROUP BY rp.idPlantilla
                ORDER BY rp.nombre
                """,
                (idUsu, fecha, fecha)
            )
            return cursor.fetchall()
    finally:
        connection.close()

# ── Detalle de una rutina (ejercicios) ────────────────────────────────────────
@app.get("/rutinas/detalle/{idPlantilla}")
def get_detalle_rutina(idPlantilla: str):
    # idPlantilla viene como string (UUID) desde Flutter.
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            sql = """
                SELECT 
                    re.idEjercicio,
                    e.nombreEj,
                    re.series,
                    re.repeticiones,
                    re.peso_kg
                FROM rutina_ejercicio re
                JOIN ejercicios e ON re.idEjercicio = e.idEjercicio
                WHERE re.idPlantilla = %s
                ORDER BY re.orden ASC
            """

            cursor.execute(sql, (idPlantilla,))
            resultados = cursor.fetchall()

            lista_ejercicios = []
            for fila in resultados:
                peso_val = fila.get("peso_kg")
                lista_ejercicios.append({
                    "idEjercicio": fila["idEjercicio"],
                    "nombreEj": fila["nombreEj"],
                    "series": fila["series"],
                    "repeticiones": fila["repeticiones"],
                    # Flutter suele consumir "peso".
                    "peso": float(peso_val) if peso_val is not None else 0.0,
                })

            return lista_ejercicios

    except Exception as e:
        print(f"Error en endpoint detalle: {e}")
        raise HTTPException(status_code=500, detail="Error interno del servidor")
    finally:
        connection.close()
# ── Eliminar rutina ───────────────────────────────────────────────────────────

@app.delete("/rutinas/{idPlantilla}")
def eliminar_rutina(idPlantilla: str):
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("DELETE FROM rutina_ejercicio WHERE idPlantilla = %s", (idPlantilla,))
            cursor.execute("DELETE FROM rutina_dias WHERE idPlantilla = %s", (idPlantilla,))
            cursor.execute("DELETE FROM rutina_plantilla WHERE idPlantilla = %s", (idPlantilla,))
            connection.commit()
            return {"success": True}
    finally:
        connection.close()

# ── Modelos para metas y peso ─────────────────────────────────────────────────
class MetaRequest(BaseModel):
    campo: str
    valor: float


class RegistroPesoRequest(BaseModel):
    peso_kg: float
    fecha: Optional[str] = None  # yyyy-MM-dd; por defecto hoy


def _verificar_propietario(idUsu: str, usuario: UsuarioActual) -> None:
    if usuario.idUsu != idUsu:
        raise HTTPException(status_code=403, detail="No autorizado para este usuario")


def _asegurar_tabla_medida(cursor) -> None:
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS medida_corporal (
            id_med VARCHAR(36) NOT NULL PRIMARY KEY,
            idUsu VARCHAR(20) NOT NULL,
            fecha DATE NOT NULL,
            peso_kg DOUBLE,
            cintura_cm DOUBLE,
            cadera_cm DOUBLE,
            pecho_cm DOUBLE,
            brazo_cm DOUBLE,
            muslo_cm DOUBLE,
            es_meta BOOL DEFAULT FALSE,
            UNIQUE KEY uq_usuario_fecha (idUsu, fecha)
        )
    """)


def _calcular_racha_entrenamiento(fechas_completadas: List[date]) -> int:
    if not fechas_completadas:
        return 0
    fechas_set = set(fechas_completadas)
    hoy = date.today()
    cursor_dia = hoy
    if cursor_dia not in fechas_set:
        cursor_dia = hoy - timedelta(days=1)
        if cursor_dia not in fechas_set:
            return 0
    racha = 0
    while cursor_dia in fechas_set:
        racha += 1
        cursor_dia -= timedelta(days=1)
    return racha


def _obtener_historial_peso(cursor, idUsu: str, limite: int = 60) -> List[dict]:
    try:
        cursor.execute(
            """
            SELECT fecha, peso_kg
            FROM medida_corporal
            WHERE idUsu = %s AND peso_kg IS NOT NULL
            ORDER BY fecha ASC
            LIMIT %s
            """,
            (idUsu, limite),
        )
        filas = cursor.fetchall()
        return [
            {
                "fecha": f["fecha"].isoformat()
                if hasattr(f["fecha"], "isoformat")
                else str(f["fecha"]),
                "peso_kg": float(f["peso_kg"]),
            }
            for f in filas
        ]
    except pymysql.err.ProgrammingError:
        return []


def _obtener_fechas_completadas(cursor, idUsu: str) -> List[date]:
    try:
        cursor.execute(
            """
            SELECT DISTINCT fecha
            FROM rutina_completada
            WHERE idUsu = %s
            ORDER BY fecha DESC
            """,
            (idUsu,),
        )
        fechas = []
        for fila in cursor.fetchall():
            f = fila["fecha"]
            if isinstance(f, datetime):
                fechas.append(f.date())
            elif isinstance(f, date):
                fechas.append(f)
            else:
                fechas.append(datetime.strptime(str(f)[:10], "%Y-%m-%d").date())
        return fechas
    except pymysql.err.ProgrammingError:
        return []


@app.post("/usuarios/{idUsu}/peso")
def registrar_peso(
    idUsu: str,
    data: RegistroPesoRequest,
    usuario: UsuarioActual = Depends(get_usuario_actual),
):
    _verificar_propietario(idUsu, usuario)

    if data.peso_kg <= 0 or data.peso_kg > 500:
        raise HTTPException(status_code=400, detail="Peso inválido (debe ser entre 0 y 500 kg)")

    if data.fecha:
        try:
            fecha_registro = datetime.strptime(data.fecha, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Fecha inválida (use yyyy-MM-dd)")
    else:
        fecha_registro = date.today()

    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            _asegurar_tabla_medida(cursor)

            cursor.execute(
                "SELECT id_med FROM medida_corporal WHERE idUsu = %s AND fecha = %s",
                (idUsu, fecha_registro),
            )
            existente = cursor.fetchone()

            if existente:
                cursor.execute(
                    """
                    UPDATE medida_corporal
                    SET peso_kg = %s, es_meta = FALSE
                    WHERE idUsu = %s AND fecha = %s
                    """,
                    (data.peso_kg, idUsu, fecha_registro),
                )
            else:
                cursor.execute(
                    """
                    INSERT INTO medida_corporal (id_med, idUsu, fecha, peso_kg, es_meta)
                    VALUES (%s, %s, %s, %s, FALSE)
                    """,
                    (str(uuid4()), idUsu, fecha_registro, data.peso_kg),
                )

            cursor.execute(
                "UPDATE usuarios SET peso = %s WHERE idUsu = %s",
                (int(round(data.peso_kg)), idUsu),
            )
            connection.commit()

            return {
                "success": True,
                "peso_kg": data.peso_kg,
                "fecha": fecha_registro.isoformat(),
            }
    except pymysql.MySQLError as e:
        raise HTTPException(status_code=500, detail=f"Error al guardar peso: {e}")
    finally:
        connection.close()


@app.get("/stats/{idUsu}")
def get_stats(idUsu: str, usuario: UsuarioActual = Depends(get_usuario_actual)):
    _verificar_propietario(idUsu, usuario)
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT peso, objetivo_entreno, peso_objetivo,
                       meta_series_semanales, meta_peso_maximo, meta_dias_semana
                FROM usuarios WHERE idUsu = %s
            """, (idUsu,))
            usu = cursor.fetchone()
            if not usu:
                raise HTTPException(status_code=404, detail="Usuario no encontrado")

            total_rutinas = 0
            dias_semana = 0
            series_semana = 0
            peso_max = 0.0
            por_tipo: list = []
            rutinas_completadas_total = 0
            rutinas_completadas_semana = 0

            try:
                cursor.execute(
                    """
                    SELECT COUNT(DISTINCT idPlantilla) as total
                    FROM rutina_plantilla WHERE idUsu = %s
                    """,
                    (idUsu,),
                )
                total_rutinas = int((cursor.fetchone() or {}).get("total") or 0)
            except pymysql.err.ProgrammingError:
                pass

            try:
                cursor.execute(
                    """
                    SELECT COUNT(DISTINCT rd.dia_semana) as dias
                    FROM rutina_plantilla rp
                    JOIN rutina_dias rd ON rp.idPlantilla = rd.idPlantilla
                    WHERE rp.idUsu = %s
                      AND rp.fecha_inicio <= CURDATE()
                      AND rp.fecha_fin >= CURDATE()
                    """,
                    (idUsu,),
                )
                dias_semana = int((cursor.fetchone() or {}).get("dias") or 0)
            except pymysql.err.ProgrammingError:
                pass

            try:
                cursor.execute(
                    """
                    SELECT COALESCE(SUM(re.series), 0) as total_series
                    FROM rutina_ejercicio re
                    JOIN rutina_plantilla rp ON re.idPlantilla = rp.idPlantilla
                    WHERE rp.idUsu = %s
                      AND rp.fecha_inicio <= CURDATE()
                      AND rp.fecha_fin >= CURDATE()
                    """,
                    (idUsu,),
                )
                series_semana = int((cursor.fetchone() or {}).get("total_series") or 0)
            except pymysql.err.ProgrammingError:
                pass

            try:
                cursor.execute(
                    """
                    SELECT COALESCE(MAX(re.peso_kg), 0) as peso_max
                    FROM rutina_ejercicio re
                    JOIN rutina_plantilla rp ON re.idPlantilla = rp.idPlantilla
                    WHERE rp.idUsu = %s AND re.peso_kg > 0
                    """,
                    (idUsu,),
                )
                peso_max = float((cursor.fetchone() or {}).get("peso_max") or 0)
            except pymysql.err.ProgrammingError:
                pass

            try:
                cursor.execute(
                    """
                    SELECT e.tipo, COUNT(*) as total
                    FROM rutina_ejercicio re
                    JOIN rutina_plantilla rp ON re.idPlantilla = rp.idPlantilla
                    JOIN ejercicios e ON re.idEjercicio = e.idEjercicio
                    WHERE rp.idUsu = %s
                    GROUP BY e.tipo ORDER BY total DESC
                    """,
                    (idUsu,),
                )
                por_tipo = cursor.fetchall() or []
            except pymysql.err.ProgrammingError:
                pass

            try:
                cursor.execute(
                    """
                    SELECT COUNT(*) as total
                    FROM rutina_completada
                    WHERE idUsu = %s
                    """,
                    (idUsu,),
                )
                rutinas_completadas_total = int(
                    (cursor.fetchone() or {}).get("total") or 0
                )
            except pymysql.err.ProgrammingError:
                pass

            try:
                cursor.execute(
                    """
                    SELECT COUNT(*) as total
                    FROM rutina_completada
                    WHERE idUsu = %s
                      AND fecha >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
                    """,
                    (idUsu,),
                )
                rutinas_completadas_semana = int(
                    (cursor.fetchone() or {}).get("total") or 0
                )
            except pymysql.err.ProgrammingError:
                pass

            historial_peso = _obtener_historial_peso(cursor, idUsu)
            fechas_completadas = _obtener_fechas_completadas(cursor, idUsu)
            racha = _calcular_racha_entrenamiento(fechas_completadas)

            peso_actual = float(usu.get("peso") or 0)
            if historial_peso:
                peso_actual = historial_peso[-1]["peso_kg"]

            peso_inicial = historial_peso[0]["peso_kg"] if historial_peso else peso_actual
            variacion_peso = round(peso_actual - peso_inicial, 1) if historial_peso else 0.0

            return {
                "peso_actual": peso_actual,
                "peso_inicial": peso_inicial,
                "variacion_peso": variacion_peso,
                "historial_peso": historial_peso,
                "objetivo_entreno": usu.get("objetivo_entreno") or "",
                "peso_objetivo": usu.get("peso_objetivo"),
                "meta_series_semanales": usu.get("meta_series_semanales"),
                "meta_peso_maximo": usu.get("meta_peso_maximo"),
                "meta_dias_semana": usu.get("meta_dias_semana"),
                "total_rutinas": total_rutinas,
                "dias_semana_activos": dias_semana,
                "series_esta_semana": series_semana,
                "peso_max_levantado": peso_max,
                "por_tipo": por_tipo,
                "racha_entrenamiento": racha,
                "rutinas_completadas_total": rutinas_completadas_total,
                "rutinas_completadas_semana": rutinas_completadas_semana,
            }
    finally:
        connection.close()


@app.patch("/stats/{idUsu}/meta")
def guardar_meta(idUsu: str, data: MetaRequest, usuario: UsuarioActual = Depends(get_usuario_actual)):
    _verificar_propietario(idUsu, usuario)
    campos_permitidos = [
        "peso_objetivo",
        "meta_series_semanales",
        "meta_peso_maximo",
        "meta_dias_semana"
    ]
    if data.campo not in campos_permitidos:
        raise HTTPException(status_code=400, detail="Campo no permitido")
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                f"UPDATE usuarios SET {data.campo} = %s WHERE idUsu = %s",
                (data.valor, idUsu)
            )
            connection.commit()
            return {"success": True}
    finally:
        connection.close()
    
    # ── Marcar rutina como completada + historial de cargas ─────────────────────
class EjercicioSesion(BaseModel):
    idEjercicio: str
    series: int
    repeticiones: int
    peso_kg: float = 0.0


class CompletarRutinaRequest(BaseModel):
    idUsu: str
    fecha: str  # "2026-05-19"
    ejercicios: Optional[List[EjercicioSesion]] = None


def _asegurar_tablas_sesion(cursor) -> None:
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS sesion_entreno (
            id_sesion VARCHAR(36) NOT NULL PRIMARY KEY,
            idUsu VARCHAR(20) NOT NULL,
            idPlantilla VARCHAR(36) NOT NULL,
            fecha DATE NOT NULL,
            UNIQUE KEY uq_sesion_usuario_rutina_fecha (idUsu, idPlantilla, fecha)
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS sesion_ejercicio (
            id VARCHAR(36) NOT NULL PRIMARY KEY,
            id_sesion VARCHAR(36) NOT NULL,
            idEjercicio VARCHAR(20) NOT NULL,
            series INT NOT NULL DEFAULT 0,
            repeticiones INT NOT NULL DEFAULT 0,
            peso_kg DOUBLE NOT NULL DEFAULT 0,
            KEY idx_sesion (id_sesion),
            KEY idx_ejercicio (idEjercicio)
        )
    """)


def _eliminar_sesion(cursor, idPlantilla: str, fecha: str) -> None:
    cursor.execute(
        "SELECT id_sesion FROM sesion_entreno WHERE idPlantilla = %s AND fecha = %s",
        (idPlantilla, fecha),
    )
    filas = cursor.fetchall()
    for fila in filas:
        id_sesion = fila["id_sesion"]
        cursor.execute("DELETE FROM sesion_ejercicio WHERE id_sesion = %s", (id_sesion,))
    cursor.execute(
        "DELETE FROM sesion_entreno WHERE idPlantilla = %s AND fecha = %s",
        (idPlantilla, fecha),
    )


def _guardar_sesion_cargas(
    cursor,
    idUsu: str,
    idPlantilla: str,
    fecha: str,
    ejercicios: List[EjercicioSesion],
) -> None:
    _asegurar_tablas_sesion(cursor)
    _eliminar_sesion(cursor, idPlantilla, fecha)

    if not ejercicios:
        return

    id_sesion = str(uuid4())
    cursor.execute(
        """
        INSERT INTO sesion_entreno (id_sesion, idUsu, idPlantilla, fecha)
        VALUES (%s, %s, %s, %s)
        """,
        (id_sesion, idUsu, idPlantilla, fecha),
    )
    for ej in ejercicios:
        cursor.execute(
            """
            INSERT INTO sesion_ejercicio
                (id, id_sesion, idEjercicio, series, repeticiones, peso_kg)
            VALUES (%s, %s, %s, %s, %s, %s)
            """,
            (
                str(uuid4()),
                id_sesion,
                ej.idEjercicio,
                ej.series,
                ej.repeticiones,
                ej.peso_kg,
            ),
        )


@app.post("/rutinas/{idPlantilla}/completar")
def completar_rutina(idPlantilla: str, data: CompletarRutinaRequest):
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT id FROM rutina_completada
                WHERE idPlantilla = %s AND fecha = %s
            """, (idPlantilla, data.fecha))
            existe = cursor.fetchone()

            if existe:
                cursor.execute("""
                    DELETE FROM rutina_completada
                    WHERE idPlantilla = %s AND fecha = %s
                """, (idPlantilla, data.fecha))
                _eliminar_sesion(cursor, idPlantilla, data.fecha)
                connection.commit()
                return {"completada": False}

            ejercicios = data.ejercicios
            if not ejercicios:
                cursor.execute(
                    """
                    SELECT idEjercicio, series, repeticiones, peso_kg
                    FROM rutina_ejercicio
                    WHERE idPlantilla = %s
                    ORDER BY orden ASC
                    """,
                    (idPlantilla,),
                )
                filas = cursor.fetchall()
                ejercicios = [
                    EjercicioSesion(
                        idEjercicio=f["idEjercicio"],
                        series=int(f["series"] or 0),
                        repeticiones=int(f["repeticiones"] or 0),
                        peso_kg=float(f["peso_kg"] or 0),
                    )
                    for f in filas
                ]

            cursor.execute("""
                INSERT INTO rutina_completada (idPlantilla, idUsu, fecha)
                VALUES (%s, %s, %s)
            """, (idPlantilla, data.idUsu, data.fecha))

            _guardar_sesion_cargas(
                cursor, data.idUsu, idPlantilla, data.fecha, ejercicios or []
            )
            connection.commit()
            return {"completada": True}
    except pymysql.MySQLError as e:
        raise HTTPException(status_code=500, detail=f"Error al completar rutina: {e}")
    finally:
        connection.close()


@app.get("/usuarios/{idUsu}/ejercicios-historial")
def ejercicios_con_historial(
    idUsu: str, usuario: UsuarioActual = Depends(get_usuario_actual)
):
    _verificar_propietario(idUsu, usuario)
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            _asegurar_tablas_sesion(cursor)
            connection.commit()
            cursor.execute(
                """
                SELECT DISTINCT se.idEjercicio, e.nombreEj
                FROM sesion_ejercicio se
                JOIN sesion_entreno s ON se.id_sesion = s.id_sesion
                JOIN ejercicios e ON se.idEjercicio = e.idEjercicio
                WHERE s.idUsu = %s
                ORDER BY e.nombreEj
                """,
                (idUsu,),
            )
            return cursor.fetchall()
    except pymysql.err.ProgrammingError:
        return []
    finally:
        connection.close()


@app.get("/usuarios/{idUsu}/historial-cargas")
def historial_cargas(
    idUsu: str,
    idEjercicio: str,
    usuario: UsuarioActual = Depends(get_usuario_actual),
):
    _verificar_propietario(idUsu, usuario)
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT s.fecha, se.peso_kg, se.series, se.repeticiones
                FROM sesion_ejercicio se
                JOIN sesion_entreno s ON se.id_sesion = s.id_sesion
                WHERE s.idUsu = %s AND se.idEjercicio = %s
                ORDER BY s.fecha ASC
                """,
                (idUsu, idEjercicio),
            )
            historial = []
            for f in cursor.fetchall():
                fecha = f["fecha"]
                historial.append({
                    "fecha": fecha.isoformat()
                    if hasattr(fecha, "isoformat")
                    else str(fecha),
                    "peso_kg": float(f["peso_kg"] or 0),
                    "series": int(f["series"] or 0),
                    "repeticiones": int(f["repeticiones"] or 0),
                    "volumen": int(f["series"] or 0)
                    * int(f["repeticiones"] or 0)
                    * float(f["peso_kg"] or 0),
                })
            return historial
    except pymysql.err.ProgrammingError:
        return []
    finally:
        connection.close()

@app.get("/rutinas/{idPlantilla}/completada")
def verificar_completada(idPlantilla: str, fecha: str):
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT id FROM rutina_completada 
                WHERE idPlantilla = %s AND fecha = %s
            """, (idPlantilla, fecha))
            return {"completada": cursor.fetchone() is not None}
    finally:
        connection.close()