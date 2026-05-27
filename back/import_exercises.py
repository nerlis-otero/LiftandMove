import json
import os
import psycopg2
from dotenv import load_dotenv

# Cargar variables de entorno desde el .env
load_dotenv()

try:
    print("1. Conectando a PostgreSQL (Supabase)...")
    conn = psycopg2.connect(
        host=os.getenv("DB_HOST"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME"),
        port=os.getenv("DB_PORT", 5432)  # El puerto por defecto de Postgres es 5432
    )
    print("2. ¡Conectado exitosamente!")
    cursor = conn.cursor()

    print("3. Leyendo JSON...")
    with open("exercises.json", "r", encoding="utf-8") as f:
        ejercicios = json.load(f)
    print(f"4. JSON cargado: {len(ejercicios)} ejercicios")

    musculos_insertados = set()

except Exception as e:
    print(f"❌ Error de inicialización: {e}")
    raise

try:
    for e in ejercicios:
        # Extraer y formatear datos del ejercicio
        ej_id = e.get("id", "")
        nombre = e.get("name", "")[:100]
        categoria = e.get("category", "")
        equipamiento = e.get("equipment", "")
        nivel = e.get("level", "")
        instrucciones = json.dumps(e.get("instructions", []))
        imagenes = json.dumps(e.get("images", []))
# Insertar ejercicio usando comillas dobles para respetar las mayúsculas en Postgres
        cursor.execute(
            """
            INSERT INTO ejercicios 
            ("idEjercicio", "nombreEj", tipo, equipamiento, nivel, instrucciones, imagenes)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT ("idEjercicio") DO NOTHING
            """,
            (ej_id, nombre, categoria, equipamiento, nivel, instrucciones, imagenes),
        )

        # Insertar músculos y relaciones
        primary = e.get("primaryMuscles", [])
        secondary = e.get("secondaryMuscles", [])

        for musculo in primary:
            if musculo not in musculos_insertados:
                cursor.execute(
                    """
                    INSERT INTO musculos ("idMusculo", "nombreMusc", grupo_muscular)
                    VALUES (%s, %s, %s)
                    ON CONFLICT ("idMusculo") DO NOTHING
                    """,
                    (musculo, musculo, "primary"),
                )
                musculos_insertados.add(musculo)

            cursor.execute(
                """
                INSERT INTO ejercicio_musculo ("idEjercicio", "idMusculo", rol)
                VALUES (%s, %s, %s)
                ON CONFLICT ("idEjercicio", "idMusculo") DO NOTHING
                """,
                (ej_id, musculo, 1), # rol 1 = primario
            )  

        for musculo in secondary:
            if musculo not in musculos_insertados:
                cursor.execute(
                    """
                    INSERT INTO musculos ("idMusculo", "nombreMusc", grupo_muscular)
                    VALUES (%s, %s, %s)
                    ON CONFLICT ("idMusculo") DO NOTHING
                    """,
                    (musculo, musculo, "secondary"),
                )
                musculos_insertados.add(musculo)

            cursor.execute(
                """
                INSERT INTO ejercicio_musculo ("idEjercicio", "idMusculo", rol)
                VALUES (%s, %s, %s)
                ON CONFLICT ("idEjercicio", "idMusculo") DO NOTHING
                """,
                (ej_id, musculo, 2), # rol 2 = secundario
            )

    # Confirmar los cambios en la base de datos
    conn.commit()
    print(f"✅ {len(ejercicios)} ejercicios importados correctamente en Supabase.")

except Exception as e:
    # En caso de error, deshacer los cambios pendientes
    conn.rollback()
    print(f"❌ Error durante la inserción de datos: {e}")

finally:
    # Cerrar conexiones de forma segura
    cursor.close()
    conn.close()
    print("Conexión finalizada.")